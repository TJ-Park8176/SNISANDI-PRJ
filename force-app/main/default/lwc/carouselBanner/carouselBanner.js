/**
 * Created by MZC01-DGCHOI on 2024-02-19.
 */

import { LightningElement, api } from 'lwc';
import basePath from '@salesforce/community/basePath'
import JQUERY from '@salesforce/resourceUrl/jQuery110';
import SLICKJS from '@salesforce/resourceUrl/SLICKJS';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

 export default class CarouselDemo extends LightningElement {
     @api imageKey1;
     @api description1;

     @api imageKey2;
     @api description2;

     @api imageKey3;
     @api description3;

     @api imageKey4;
     @api description4;

     @api imageKey5;
     @api description5;

     @api imageKey6;
     @api description6;

     options = { autoScroll: true, autoScrollTime: 4 };
     items = [];
     IMAGE_PATH = basePath + '/sfsites/c/cms/delivery/media/';

     imageUrl1;
     imageUrl2;
     imageUrl3;
     imageUrl4;
     imageUrl5;
     imageUrl6;

     connectedCallback() {
        this.imageUrl1 = this.IMAGE_PATH + this.imageKey1;
        this.imageUrl2 = this.IMAGE_PATH + this.imageKey2;
        this.imageUrl3 = this.IMAGE_PATH + this.imageKey3;
        this.imageUrl4 = this.IMAGE_PATH + this.imageKey4;
        this.imageUrl5 = this.IMAGE_PATH + this.imageKey5;
        this.imageUrl6 = this.IMAGE_PATH + this.imageKey6;


        Promise.all([
            loadScript(this, JQUERY + '/jquery-1.11.0.min.js')
        ]).then(() => {
            loadScript(this, JQUERY + '/jquery-migrate-1.2.1.min.js')
        }).then(() => {
            Promise.all([
                loadStyle(this, SLICKJS + '/slick-1.8.1/slick/slick.css'),
                loadStyle(this, SLICKJS + '/slick-1.8.1/slick/slick-theme.css'),
                loadScript(this, SLICKJS + '/slick-1.8.1/slick/slick.min.js')
            ]).then(() => {
                this.initializeSlick();
            }).catch(error => {
                console.log(error);
            });
        }).catch(error => {
            console.log(error);
        });

         if (this.imageKey1) {
             this.items.push({
                 image: this.IMAGE_PATH + this.imageKey1,
                 header: '배너',
                 description: this.description1
             });
         }
         if (this.imageKey2) {
             this.items.push({
                 image: this.IMAGE_PATH + this.imageKey2,
                 header: 'Header 2',
                 description: this.description2
             });
         }
         if (this.imageKey3) {
             this.items.push({
                 image: this.IMAGE_PATH + this.imageKey3,
                 header: 'Header 3',
                 description: this.description4
             });
         }
         if (this.imageKey4) {
             this.items.push({
                 image: this.IMAGE_PATH + this.imageKey4,
                 header: 'Header 4',
                 description: this.description2
             });
         }
         if (this.imageKey5) {
             this.items.push({
                 image: this.IMAGE_PATH + this.imageKey5,
                 header: 'Header 5',
                 description: this.description5
             });
         }
         if (this.imageKey6) {
             this.items.push({
                 image: this.IMAGE_PATH + this.imageKey6,
                 header: 'Header 6',
                 description: this.description6
             });
         }
     }

     disconnectedCallback() {
        this.template.querySelector('.custom-carousel').style.display = 'none';
     }

     async initializeSlick() {
         const result = await $(this.template.querySelector('.custom-carousel')).slick({
            dots: true,
            infinite: true,
            arrows: true,
            slidesToShow: 3,
            slidesToScroll: 1,
            autoplay: true,
            autoplaySpeed: 4000,
            centerMode: true,
            variableWidth: true
         });

         this.template.querySelector('.custom-carousel').style.display = 'block';
     }


     /*
     items = [
         {
             image: 'https://images.pexels.com/photos/132037/pexels-photo-132037.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500',
             header: 'Landscape 1',
             description: 'Demo image for carousel.',
             href: 'https://images.pexels.com/photos/132037/pexels-photo-132037.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500'
         }, {
             video: 'https://www.youtube.com/embed/SLaWOkc3bC8',
             header: 'Video 1',
             description: 'Demo video for carousel.',
         },
         {
             video: 'https://player.vimeo.com/video/241135386',
             header: 'Video 2',
             description: 'Demo image for carousel.',
         }, {
             image: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjExMDk0fQ&w=1000&q=80',
             header: 'Landscape 4',
             description: 'Demo image for carousel.',
         },
         {
             image: 'https://cdn.cnn.com/cnnnext/dam/assets/190517091026-07-unusual-landscapes-travel.jpg',
             header: 'Landscape 5',
             description: 'Demo image for carousel.',
         }, {
             image: 'https://solablogdotcom.files.wordpress.com/2015/11/lake-district-1009459_1920.png?w=1134',
             header: 'Landscape 6',
             description: 'Demo image for carousel.',
         },
         {
             image: 'https://i.unu.edu/media/ourworld.unu.edu-en/article/8564/Champions_of_Cumbria_Human_Landscapes1.jpg',
             header: 'Landscape 7',
             description: 'Demo image for carousel.',
         }, {
             image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcSVGWCqosuufmXUpuQDGpktXc2e1PaIB2K-cOhJBVEFOuP4hjWR&usqp=CAU',
             header: 'Landscape 8',
             description: 'Demo image for carousel.',
         }
     ]
     */
 }