/**
 * Created by MZC01-DGCHOI on 2024-02-19.
 */

/*
MIT License

Copyright (c) 2020 Playground, https://www.playg.app

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import { LightningElement, api, track } from 'lwc';

export default class CarouselComponent extends LightningElement {

    @api items;
    @api options;
    @track components;
    @track showPlayIcon;
    activeComponent = 0;
    loaded = false;
    autoScroll;
    intervalVar;

    navigate(event) {
        this.activeComponent = parseInt(event.target.dataset.id);
        this.arrangeComponents();
    }

    arrangeComponents() {
        let untrackedComponents = [];
        let iterator = 0;
        this.items.forEach(item => {
            let temp = { ...item };
            temp.id = iterator;
            temp.contentId = 'content-id-' + iterator;
            temp.indicatorId = 'indicator-id-' + iterator;
            if(temp.href){
                temp.href='javascript:void(0);';
            }
            if (iterator === this.activeComponent) {
                temp.hidden = false;
                temp.tabindex = 0;
                temp.active = true;
                temp.indicatorClass = 'slds-carousel__indicator-action slds-is-active';
                temp.contentClass = 'slds-carousel__panel';
            } else {
                temp.hidden = true;
                temp.tabindex = -1;
                temp.active = false;
                temp.indicatorClass = 'slds-carousel__indicator-action';
                temp.contentClass = 'slds-carousel__panel panel-hide';
            }
            untrackedComponents.push(temp);
            iterator++;
        });
        this.components = untrackedComponents;
    }

    togglePlay(){
        if(!this.showPlayIcon){
            clearInterval(this.intervalVar);
            this.showPlayIcon = true;
        }else{
            this.checkOptions();
        }
    }

    checkOptions() {
        if (this.options) {
            if (this.options.autoScroll && this.options.autoScrollTime) {
                this.autoScroll = true;
                this.showPlayIcon = false;
                this.intervalVar = setInterval(() => {
                    if (this.activeComponent === (this.components.length - 1)) {
                        this.activeComponent = 0;
                    } else {
                        this.activeComponent++;
                    }
                    this.arrangeComponents();
                }, this.options.autoScrollTime * 1000);
            }
        }
    }

    renderedCallback() {
        if (!this.loaded) {
            this.arrangeComponents();
            this.checkOptions();
            this.loaded = true;
        }
    }
}