import { Router } from 'express';
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
