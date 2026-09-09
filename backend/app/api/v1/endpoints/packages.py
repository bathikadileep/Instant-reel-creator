import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.exceptions import NotFoundException
from app.repositories.package_repository import PackageRepository
from app.schemas.booking import PackageResponse

router = APIRouter()


@router.get(
    "/",
    response_model=List[PackageResponse],
    status_code=status.HTTP_200_OK,
    summary="List Active Reel Packages",
    description="Returns all active instant reel packages including 10-minute rapid delivery SLA packages.",
)
async def list_packages(
    db: AsyncSession = Depends(get_db),
) -> List[PackageResponse]:
    repo = PackageRepository(db)
    packages = await repo.get_active_packages()
    if not packages:
        # Seed if table is empty
        packages = await repo.seed_default_packages_if_empty()
    return [PackageResponse.model_validate(p) for p in packages]


@router.get(
    "/{package_id}",
    response_model=PackageResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Package Details",
)
async def get_package(
    package_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> PackageResponse:
    repo = PackageRepository(db)
    pkg = await repo.get_by_id(package_id)
    if not pkg or not pkg.is_active:
        raise NotFoundException("Package not found or inactive")
    return PackageResponse.model_validate(pkg)
