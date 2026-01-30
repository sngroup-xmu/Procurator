"""
Command-line entrypoints built on top of the dslc library.

We keep CLI code here (instead of deep under Procurator/...) so that:
  - imports stay within the dslc package (no sys.path hacks)
  - workflows are reusable from Python without shelling out
"""

