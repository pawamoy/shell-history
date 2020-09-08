# Why does this file exist, and why not put this in `__main__`?
#
# You might be tempted to import things from `__main__` later,
# but that will cause problems: the code will get executed twice:
#
# - When you run `python -m shellhistory` python will execute
#   `__main__.py` as a script. That means there won't be any
#   `shellhistory.__main__` in `sys.modules`.
# - When you import `__main__` it will get executed again (as a module) because
#   there's no `shellhistory.__main__` in `sys.modules`.

"""Module that contains the command line application."""

import argparse
from pathlib import Path
from typing import List, Optional

from . import db


def get_parser() -> argparse.ArgumentParser:
    """
    Return the CLI argument parser.

    Returns:
        An argparse parser.
    """
    parser = argparse.ArgumentParser(prog="shellhistory-cli")

    group = parser.add_mutually_exclusive_group()
    group.add_argument("--location", dest="location", action="store_true")
    group.add_argument("--web", dest="web", action="store_true")
    group.add_argument("--import", dest="import_file", action="store_true")

    return parser


def main(args: Optional[List[str]] = None) -> int:
    """
    Run the main program.

    This function is executed when you type `shellhistory` or `python -m shellhistory`.

    Arguments:
        args: Arguments passed from the command line.

    Returns:
        An exit code.
    """
    parser = get_parser()
    args = parser.parse_args(args=args)

    if args.location:
        return location()
    elif args.web:
        return web()
    elif args.import_file:
        report = db.update()

    return 0


def location():
    print(Path(__file__).parent / "shellhistory.sh")
    return 0


def web():
    from .app import app

    app.run()
