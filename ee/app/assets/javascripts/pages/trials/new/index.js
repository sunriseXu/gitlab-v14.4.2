import { trackSaasTrialSkip } from '~/google_tag_manager';
import { initTrialCreateLeadForm } from 'ee/trials/init_create_lead_form';

initTrialCreateLeadForm();
trackSaasTrialSkip();
