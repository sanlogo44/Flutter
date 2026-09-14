/// Generates users and projects module files (routes, controller, service).
library;

class UsersProjectsGenerator {
  UsersProjectsGenerator();

  String userRoutes() => '''import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import { getUserController, updateUserController } from './user.controller';
import { validateBody } from '../middleware/request-validation';
import { updateUserSchema } from './user.schemas';

export const userRoutes = Router();

userRoutes.get('/me', requireAuth, getUserController);
userRoutes.put('/me', requireAuth, validateBody(updateUserSchema), updateUserController);
''';

  String userSchemas() => '''import { z } from 'zod';

export const updateUserSchema = z.object({
  displayName: z.string().min(1).max(100).optional(),
  avatarUrl: z.string().url().optional(),
});

export type UpdateUserInput = z.infer<typeof updateUserSchema>;
''';

  String userController() => '''import { Request, Response } from 'express';
import { prisma } from '../database/prisma';
import { ApiError } from '../middleware/error-handler';

export async function getUserController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      email: true,
      displayName: true,
      avatarUrl: true,
      emailVerified: true,
      createdAt: true,
      updatedAt: true,
    },
  });

  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  res.json({ user });
}

export async function updateUserController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const { displayName, avatarUrl } = req.body;

  const updated = await prisma.user.update({
    where: { id: userId },
    data: {
      ...(displayName !== undefined && { displayName }),
      ...(avatarUrl !== undefined && { avatarUrl }),
    },
    select: {
      id: true,
      email: true,
      displayName: true,
      avatarUrl: true,
      updatedAt: true,
    },
  });

  res.json({ user: updated });
}
''';

  String projectRoutes() => '''import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import { validateBody, validateParams } from '../middleware/request-validation';
import {
  createProjectSchema,
  updateProjectSchema,
  projectIdSchema,
  addMemberSchema,
} from './project.schemas';
import {
  createProjectController,
  listProjectsController,
  getProjectController,
  updateProjectController,
  deleteProjectController,
  addMemberController,
  listMembersController,
  removeMemberController,
} from './project.controller';

export const projectRoutes = Router();

projectRoutes.use(requireAuth);

projectRoutes.post('/', validateBody(createProjectSchema), createProjectController);
projectRoutes.get('/', listProjectsController);
projectRoutes.get('/:id', validateParams(projectIdSchema), getProjectController);
projectRoutes.put('/:id', validateParams(projectIdSchema), validateBody(updateProjectSchema), updateProjectController);
projectRoutes.delete('/:id', validateParams(projectIdSchema), deleteProjectController);
projectRoutes.post('/:id/members', validateParams(projectIdSchema), validateBody(addMemberSchema), addMemberController);
projectRoutes.get('/:id/members', validateParams(projectIdSchema), listMembersController);
projectRoutes.delete('/:id/members/:userId', validateParams(projectIdSchema), removeMemberController);
''';

  String projectSchemas() => '''import { z } from 'zod';

export const createProjectSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  metadata: z.record(z.unknown()).optional(),
});

export const updateProjectSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).optional(),
  metadata: z.record(z.unknown()).optional(),
});

export const projectIdSchema = z.object({
  id: z.string().min(1),
});

export const addMemberSchema = z.object({
  userId: z.string().min(1),
  role: z.enum(['admin', 'editor', 'viewer']).default('editor'),
});

export type CreateProjectInput = z.infer<typeof createProjectSchema>;
export type UpdateProjectInput = z.infer<typeof updateProjectSchema>;
export type AddMemberInput = z.infer<typeof addMemberSchema>;
''';

  String projectController() => '''import { Request, Response } from 'express';
import { prisma } from '../database/prisma';
import { ApiError } from '../middleware/error-handler';

export async function createProjectController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const { name, description, metadata } = req.body;

  const project = await prisma.\$transaction(async (tx) => {
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
''';
}
