/**
 * Created by MZC01-DGCHOI on 2024-03-07.
 */

public with sharing class Sandi_ProductReviewController {

    @AuraEnabled(Cacheable=true)
    public static List<Review_SANDI__c> getProductReviews(String productId) {
        List<Review_SANDI__c> returnReviews = [
                SELECT Id, Rating__c, Description__c, Owner.Name, CreatedDate
                FROM Review_SANDI__c
                WHERE Product__c =: productId
                ORDER BY Rating__c ASC
        ];

        return returnReviews;
    }


    /**
     * @param productId
     *
     * @return 상품별 리뷰 Summary
     */
    @AuraEnabled(Cacheable=true)
    public static ProductReviewSummaryInfo getProductReviewSummary(String productId) {

        List<AggregateResult> productReviews = [
            SELECT COUNT(Id) CNT, Rating__c
            FROM Review_SANDI__c
            WHERE Product__c =: productId
            GROUP BY Rating__c
            ORDER BY Rating__c DESC
        ];

        Integer sumOfReviews  = 0;
        Integer sumOfRating   = 0;
        Decimal averageRating = 0.0;

        for(AggregateResult agg : productReviews) {
            Integer rating = Integer.valueOf(agg.get('Rating__c'));
            Integer count  = Integer.valueOf(agg.get('CNT'));
            sumOfReviews += count;
            sumOfRating  += rating * count;
        }

        System.debug('sumOfReviews ? ' + sumOfReviews);
        averageRating = (sumOfRating / (sumOfReviews * 1.0)).setScale(1, System.RoundingMode.HALF_UP);

        Map<String, Decimal> ratingPercentMap = new Map<String, Decimal>();
        List<RatingDistribution> ratingDistributions = new List<RatingDistribution>();

        for(AggregateResult agg : productReviews) {
            String rating   = String.valueOf(agg.get('Rating__c'));
            Integer count   = Integer.valueOf(agg.get('CNT'));
            Decimal percent = ((count / (sumOfReviews * 1.0) * 100).setScale(0, System.RoundingMode.HALF_UP));

            ratingPercentMap.put(rating, percent);
        }

        System.debug('ratingPercentMap: ' + ratingPercentMap);

        for(Integer i=5; i>=1; i--) {
            String mapKey = String.valueOf(i);

            System.debug(mapKey);
            System.debug(ratingPercentMap.containsKey(mapKey));
            RatingDistribution rd = new RatingDistribution();
            rd.rating  = mapKey;
            rd.percent = ratingPercentMap.containsKey(mapKey) ? ratingPercentMap.get(mapKey) : 0;
            ratingDistributions.add(rd);
        }

        ProductReviewSummaryInfo reviewSummaryInfo = new ProductReviewSummaryInfo();
        reviewSummaryInfo.averageRating      = averageRating;
        reviewSummaryInfo.sumOfReviews       = sumOfReviews;
        reviewSummaryInfo.ratingDistribution = ratingDistributions;

        System.debug('reviewSummaryInfo: ' + reviewSummaryInfo);
        return reviewSummaryInfo;
    }

    public class ProductReviewSummaryInfo {
        @AuraEnabled
        public Decimal averageRating;
        @AuraEnabled
        public Integer sumOfReviews;
        @AuraEnabled
        public List<RatingDistribution> ratingDistribution;

    }

    public class RatingDistribution {
        @AuraEnabled
        public String rating;
        @AuraEnabled
        public Decimal percent;
    }
}