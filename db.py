import os
import shutil
from base64 import b64decode
from collections import namedtuple
from datetime import datetime

from sqlalchemy import (Column, DateTime, Integer, Interval, String, Text,
                        UnicodeText, UniqueConstraint, create_engine, exc)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

DB_PATH = os.getenv('SHELLHISTORY_DB', 'shellhistory.db')
HISTFILE_PATH = os.getenv('SHELLHISTORY_FILE', 'shellhistory')

Base = declarative_base()
engine = create_engine('sqlite:///%s' % DB_PATH)
Session = sessionmaker(bind=engine)


class History(Base):
    __tablename__ = 'history'
    __table_args__ = (UniqueConstraint('start', 'uuid'), {'useexisting': True})

    id = Column(Integer, primary_key=True)
    start = Column(DateTime)
    stop = Column(DateTime)
    duration = Column(Interval)
    host = Column(String)
    user = Column(String)
    uuid = Column(String)
    tty = Column(String)
    parents = Column(Text)
    shell = Column(String)
    level = Column(Integer)
    type = Column(String)
    code = Column(Integer)
    path = Column(String)
    cmd = Column(UnicodeText)

    def __repr__(self):
        return "<History(path='%s', cmd='%s')>" % (self.path, self.cmd)


def create_tables():
    Base.metadata.create_all(engine)


def flush():
    session = Session()
    session.query(History).delete()
    session.commit()


def delete_table(table=History):
    table.__table__.drop(engine)


def line_split(line):
    return namedtuple(
        'history',
        'start stop uuid parents host user tty '
        'path shell level type code cmd')(
            *line.split(':', 12))


def namedtuple_to_history(nt):
    start = datetime.fromtimestamp(float(nt.start)/1000000.0)
    stop = datetime.fromtimestamp(float(nt.stop)/1000000.0)
    duration = stop - start
    return History(
        start=start,
        stop=stop,
        duration=duration,
        host=nt.host,
        user=nt.user,
        path=b64decode(nt.path).decode().rstrip('\n'),
        uuid=nt.uuid,
        tty=nt.tty,
        parents=b64decode(nt.parents).decode().rstrip('\n'),
        shell=nt.shell,
        level=nt.level,
        type=nt.type,
        code=nt.code,
        cmd=nt.cmd)


def line_to_history(line):
    return namedtuple_to_history(line_split(line))


def parse_file(path):
    obj_list = []
    with open(path) as stream:
        current_obj = None
        for i, line in enumerate(stream, 1):
            first_char, line = line[0], line[1:].rstrip('\n')
            if first_char == ':':
                # new command
                if current_obj is not None:
                    obj_list.append(current_obj)
                current_obj = line_to_history(line)
            elif first_char == ';':
                # multiline command
                if current_obj is None:
                    continue  # orphan line
                current_obj.cmd += '\n' + line
            else:
                # would only happen if file is corrupted
                raise ValueError('invalid line %s starting with %s' % (
                    i, first_char))
        if current_obj is not None:
            obj_list.append(current_obj)
    return obj_list


def insert(obj_list, session, one_by_one=False):
    report = namedtuple('report', 'inserted duplicates')
    if obj_list:
        if one_by_one:
            duplicates, inserted = 0, 0
            for obj in obj_list:
                try:
                    session.add(obj)
                    session.commit()
                    inserted += 1
                except exc.IntegrityError:
                    session.rollback()
                    duplicates += 1
            return report(inserted, duplicates)
        else:
            session.add_all(obj_list)
            session.commit()
            return report(len(obj_list), 0)
    return report(0, 0)


def import_file(path):
    obj_list = parse_file(path)
    session = Session()
    try:
        report = insert(obj_list, session)
    except exc.IntegrityError:
        session.rollback()
        report = insert(obj_list, session, one_by_one=True)
    return report


def import_history():
    if not os.path.exists(HISTFILE_PATH):
        raise ValueError('%s: no such file' % HISTFILE_PATH)
    return import_file(HISTFILE_PATH)


def update():
    try:
        report = import_history()
    except exc.OperationalError:
        create_tables()
        report = import_history()
    return report
