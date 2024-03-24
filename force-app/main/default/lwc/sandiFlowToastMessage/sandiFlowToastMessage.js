import { LightningElement, api} from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationFinishEvent } from "lightning/flowSupport";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class SandiFlowToastMessage extends NavigationMixin(LightningElement) {
    hasRendered = false;
 
     @api recordId;
     @api objectApiName;
     @api title;
     @api variant;
     @api message;
     @api mode;
     @api triggerNavigationNextEvent;
 
     @api
     availableActions = [];

    renderedCallback() {
        console.log('EEEEEEEE');
         if (!this.hasRendered) {
             this.hasRendered = true;
             this.showToastMessage();
         }
     }
 
    async showToastMessage() {
            
        const event = new ShowToastEvent({
            "title": this.title,
            "variant": this.variant,
            "message": this.message,
            "mode" : this.mode
        });
        console.log('event!!');
        console.log(event);
        this.dispatchEvent(event);
 
        if (this.triggerNavigationNextEvent) {
            if (this.availableActions.find(action => action === 'NEXT')) {
                const navigateNextEvent = new FlowNavigationNextEvent();
                console.log('navigateNextEvent');
                this.dispatchEvent(navigateNextEvent);
            } else if (this.availableActions.find(action => action === 'FINISH')) {
                console.log('Finish');
                const navigateFinishEvent = new FlowNavigationFinishEvent();
                console.log('navigateFinishEvent');
                this.dispatchEvent(navigateFinishEvent);
            
                const refreshViewEvent = new CustomEvent('refreshView');
                console.log('refreshView');
                this.dispatchEvent(refreshViewEvent);
            }
        }
    }


}