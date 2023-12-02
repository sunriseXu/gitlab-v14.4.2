import PasswordValidator from 'ee/password/password_validator';
import { pipelineMinutes } from '../pipeline_minutes';

pipelineMinutes();
new PasswordValidator(); // eslint-disable-line no-new
