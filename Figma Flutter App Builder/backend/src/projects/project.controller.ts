import { Request, Response } from 'express';
import { prisma } from '../database/prisma';
import { ApiError } from '../middleware/error-handler';

export async function createProjectController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const { name, description, metadata } = req.body;

  const project = await prisma.$transaction(async (tx) => {
    const newProject = await tx.project.create({
      data: {
        name,
        description: description || null,
        metadata: metadata || undefined,
        ownerId: userId,
      },
    });

    await tx.projectMember.create({
      data: {
        projectId: newProject.id,
        userId,
        role: 'owner',
      },
    });

    return newProject;
  });

  res.status(201).json({ project });
}

export async function listProjectsController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;

  const projects = await prisma.project.findMany({
    where: {
      OR: [
        { ownerId: userId },
        { members: { some: { userId } } },
      ],
    },
    include: {
      members: {
        select: { userId: true, role: true },
      },
    },
    orderBy: { updatedAt: 'desc' },
  });

  res.json({ projects });
}

export async function getProjectController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const id = req.params.id as string;

  const project = await prisma.project.findUnique({
    where: { id },
    include: { members: true },
  });

  if (!project) {
    throw new ApiError(404, 'Project not found');
  }

  const isMember = project.ownerId === userId ||
    project.members.some((m: any) => m.userId === userId);
  if (!isMember) {
    throw new ApiError(403, 'Access denied');
  }

  res.json({ project });
}

export async function updateProjectController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const id = req.params.id as string;
  const { name, description, metadata } = req.body;

  const project = await prisma.project.findUnique({ where: { id } });
  if (!project) {
    throw new ApiError(404, 'Project not found');
  }

  const member = await prisma.projectMember.findUnique({
    where: { projectId_userId: { projectId: id, userId } },
  });

  const canEdit = project.ownerId === userId ||
    (member && (member.role === 'admin' || member.role === 'editor'));
  if (!canEdit) {
    throw new ApiError(403, 'Insufficient permissions');
  }

  const updated = await prisma.project.update({
    where: { id },
    data: {
      ...(name !== undefined && { name }),
      ...(description !== undefined && { description }),
      ...(metadata !== undefined && { metadata }),
    },
  });

  res.json({ project: updated });
}

export async function deleteProjectController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const id = req.params.id as string;

  const project = await prisma.project.findUnique({ where: { id } });
  if (!project) {
    throw new ApiError(404, 'Project not found');
  }

  if (project.ownerId !== userId) {
    throw new ApiError(403, 'Only the owner can delete a project');
  }

  await prisma.project.delete({ where: { id } });

  res.json({ success: true });
}

export async function addMemberController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const id = req.params.id as string;
  const { userId: newMemberId, role } = req.body;

  const project = await prisma.project.findUnique({ where: { id } });
  if (!project) {
    throw new ApiError(404, 'Project not found');
  }

  if (project.ownerId !== userId) {
    throw new ApiError(403, 'Only the owner can add members');
  }

  await prisma.projectMember.create({
    data: { projectId: id, userId: newMemberId, role },
  });

  res.status(201).json({ success: true });
}

export async function listMembersController(req: Request, res: Response): Promise<void> {
  const id = req.params.id as string;

  const members = await prisma.projectMember.findMany({
    where: { projectId: id },
    include: {
      user: {
        select: { id: true, email: true, displayName: true },
      },
    },
  });

  res.json({ members });
}

export async function removeMemberController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const id = req.params.id as string;
  const memberToRemoveId = req.params.userId as string;

  const project = await prisma.project.findUnique({ where: { id } });
  if (!project) {
    throw new ApiError(404, 'Project not found');
  }

  const canRemove = project.ownerId === userId || userId === memberToRemoveId;
  if (!canRemove) {
    throw new ApiError(403, 'Insufficient permissions');
  }

  await prisma.projectMember.deleteMany({
    where: { projectId: id, userId: memberToRemoveId },
  });

  res.json({ success: true });
}
