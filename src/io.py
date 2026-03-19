import pandas as pd
from pathlib import Path

def load_csv(path: str | Path):

    """Load .csv into DataFrame. Ignores unreadable rows"""

    return pd.read_csv(path, on_bad_lines = "skip", engine = "python")


def save_csv(data: pd.DataFrame, path: str | Path):

    """Save DataFrame into .csv"""

    data.to_csv(path, index = False)
