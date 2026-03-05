from pydantic import BaseModel
from typing import Optional

class ManualExpense(BaseModel):
    amount: float
    items: Optional[str] = None
    category: Optional[str] = None
    note: Optional[str] = None