import os
import shutil
import sys
import time
import uuid
from base64 import b64decode
from collections import namedtuple
from datetime import datetime

from sqlalchemy import (Column, DateTime, Integer, String, Text, UnicodeText,
                        UniqueConstraint, create_engine)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import exc, sessionmaker

DB_PATH = os.getenv('SHELLHISTORY_DB', 'shellhistory.db')
HISTFILE_PATH = os.environ.get('SHELLHISTORY_FILE', 'shellhistory')
UUID = str(uuid.uuid4())

Base = declarative_base()
engine = create_engine('sqlite:///%s' % DB_PATH)
Session = sessionmaker(bind=engine)


class History(Base):
    __tablename__ = 'history'
    __table_args__ = (UniqueConstraint('start', 'uuid'), {'useexisting': True})

    id = Column(Integer, primary_key=True)
    start = Column(DateTime)
    stop = Column(DateTime)
    host = Column(String)
    user = Column(String)
    uuid = Column(String)
    tty = Column(String)
    parents = Column(Text)
    shell = Column(String)
    level = Column(Integer)
    code = Column(Integer)
    path = Column( String)
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
        'start stop uuid parents host user tty path shell level code cmd')(
            *line.split(':', 11))


def namedtuple_to_history(nt):
    try:
        return History(
            start=datetime.fromtimestamp(float(nt.start)/1000000.0),
            stop=datetime.fromtimestamp(float(nt.stop)/1000000.0),
            host=nt.host,
            user=nt.user,
            path=b64decode(nt.path).decode().rstrip('\n'),
            uuid=nt.uuid,
            tty=nt.tty,
            parents=b64decode(nt.parents).decode().rstrip('\n'),
            shell=nt.shell,
            level=nt.level,
            code=nt.code,
            cmd=nt.cmd)
    except ValueError:
        print(nt)


def line_to_history(line):
    return namedtuple_to_history(line_split(line))


def import_file(path):
    history_list = []
    with open(path) as stream:
        current_history = None
        for i, line in enumerate(stream, 1):
            first_char, line = line[0], line[1:].rstrip('\n')
            if first_char == ':':
                # new command
                if current_history is not None:
                    history_list.append(current_history)
                current_history = line_to_history(line)
            elif first_char == ';':
                # multiline command
                if current_history is None:
                    continue  # orphan line
                current_history.cmd += '\n' + line
            else:
                # would only happen if file is corrupted
                raise ValueError('invalid line %s starting with %s' % (i, first_char))
        history_list.append(current_history)
    session = Session()
    session.add_all(history_list)
    session.commit()


def backup_file(path):
    backup_path = '%s.%s.bak' % (path, UUID)
    shutil.move(path, backup_path)
    with open(path, 'a'):
        os.utime(path)

def import_history():
    if not os.path.exists(HISTFILE_PATH):
        raise ValueError('%s: no such file' % HISTFILE_PATH)
    create_tables()
    import_file(HISTFILE_PATH)


def backup_history():
    if not os.path.exists(HISTFILE_PATH):
        raise ValueError('%s: no such file' % HISTFILE_PATH)
    backup_file(HISTFILE_PATH)


def update():
    create_tables()
    try:
        import_history()
    except exc.UnmappedInstanceError:
        pass
    else:
        backup_history()
