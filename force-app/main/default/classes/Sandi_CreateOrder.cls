/**
 * Created by MZC01-DGCHOI on 2024-03-05.
 */

/**
* @description This is a sample implementation of Create Order extension.
* This class must extend CartExtension.CheckoutCreateOrder and must be linked to the Create Order extension point (Commerce_Domain_Checkout_CreateOrder).
*/
public virtual class Sandi_CreateOrder extends CartExtension.CheckoutCreateOrder{

    public virtual override CartExtension.CreateOrderResponse createOrder(CartExtension.CreateOrderRequest request) {

        CartExtension.Cart         cart         = request.getCart();
        CartExtension.CartItemList requestCartItemList = cart.getCartItems();
        String cartId = cart.getId();

        System.debug('@ cartId : '       + cartId);
        System.debug('@ requestCartItemList : ' + requestCartItemList);

        Set<String> cartItemIdSet = new Set<String>();
        for(Integer i=0; i<requestCartItemList.size(); i++) {
            CartExtension.CartItem cartItem = requestCartItemList.get(i);
            cartItemIdSet.add(cartItem.getId());
        }

        //상품-판매유형 매핑
        List<CartItem> cartItemInfos = [
                SELECT Id, Product2Id, SalesType_SANDI__c
                FROM CartItem
                WHERE Id IN :cartItemIdSet
        ];

        Map<String, String> productIdSalesTypeMap = new Map<String, String>();
        for(CartItem cartItem : cartItemInfos) {
            productIdSalesTypeMap.put(
                    cartItem.Product2Id,
                    cartItem.SalesType_SANDI__c
            );
        }
        System.debug('@productIdSalesTypeMap : ' + productIdSalesTypeMap);

        CartExtension.CreateOrderResponse response = callDefault(request);
        CartExtension.OrderGraph orderGraph        = response.getOrderGraph();
        Order order = orderGraph.getOrder();

        System.debug('@ order before : ' + order);

        order.Description = '제품의 총 반올림 비용 : ';
        List<OrderItem> orderItems = orderGraph.getOrderItems();
        Decimal roundedPrice = 0.0;

        //배송비
        OrderItem deliveryOrderItemCopy = new OrderItem();

        for(Integer i=0; i<orderItems.size(); i++) {

            OrderItem orderItem = orderItems[i];
            System.debug('@@ orderItem : ' + orderItem);

            String salesType = productIdSalesTypeMap.get(orderItem.Product2Id);
            System.debug('@@ salesType : ' + salesType);

            //판매형일 경우만 orderItem 생성함
            if(salesType != '판매형') {
                orderItems.remove(i);
                continue;
            }

            //배송비 clone 테스트
            if(orderItem.Type == 'Delivery Charge') {
                deliveryOrderItemCopy = orderItem.clone();
                deliveryOrderItemCopy.Product2Id = '01t1y00000613kjAAA';
                deliveryOrderItemCopy.UnitPrice = 5555;
                deliveryOrderItemCopy.Partner__c = '0011y00000liSB1AAM';
            }

            //금핵 합산
            roundedPrice += orderItems[i].UnitPrice.round(System.RoundingMode.CEILING);
        }

        System.debug('@orderItem size before? ' + orderItems.size());
        order.Description += roundedPrice;
        orderItems.add(deliveryOrderItemCopy);
        orderGraph.addNode(deliveryOrderItemCopy);

        for(OrderItem orderItem : orderItems) {
            System.debug('## O/I : ' + orderItem);
        }

        System.debug('@ orderItems after : ' + orderItems);
        System.debug('@ response : ' + response);

        System.debug('@orderItem size after ? ' + orderItems.size());

        for(Integer i=0; i<orderItems.size(); i++) {
            System.debug('@type?' + orderItems[i].Type);
        }


        return response;

        /*CartExtension.OrderGraph orderGraph = new CartExtension.OrderGraph();
        Order order = orderGraph.getOrder();

        CartExtension.CartDeliveryGroupList cdgList = cart.getCartDeliveryGroups();
        for (Integer i = 0; i < cdgList.size(); i++) {
            CartExtension.CartDeliveryGroup cdg = cdgList.get(i);
            // create orderDeliveryGroup
            OrderDeliveryGroup odg    = new OrderDeliveryGroup();
            odg.DeliverToName         = cdg.getDeliverToName();
            odg.OrderDeliveryMethodId = cdg.getDeliveryMethodId();
            orderGraph.addNode(odg);

            // create orderItems
            for (Integer j = 0; j < cartItemList.size(); j++) {
                CartExtension.CartItem cartItem = cartItemList.get(j);
                OrderItem orderItem = new OrderItem();

                if (CartExtension.SalesItemTypeEnum.PRODUCT.equals(cartItem.getType())) {
                    orderItem.Type = 'Order Product';
                } else {
                    orderItem.Type = 'Delivery charge';
                }
                if (orderItem.UnitPrice == null) {
                    orderItem.UnitPrice = cartItem.getSalesPrice() == null ? cartItem.getListPrice() : cartItem.getSalesPrice();
                }
                if (orderItem.ListPrice == null) {
                    orderItem.ListPrice = cartItem.getSalesPrice();
                }

                orderItem.OrderDeliveryGroupId = odg.Id;
                orderItem.Product2Id           = cartItem.getProduct2Id();
                orderItem.Quantity             = cartItem.getQuantity();
                orderItem.ListPrice            = cartItem.getListPrice();
                orderItem.UnitPrice            = cartItem.getNetUnitPrice();
                orderItem.GrossUnitPrice       = cartItem.getNetUnitPrice();
                orderItem.TotalLineAmount      = cartItem.getTotalLineNetAmount();
                orderItem.Description          = cartItem.getName();
                orderGraph.addNode(orderItem);
            }
        }

        CartExtension.CreateOrderResponse response = new CartExtension.CreateOrderResponse(orderGraph);

        System.debug('@ orderGraph : ' + orderGraph);
        System.debug('@ response : '   + response);

        return response;*/


    }

    @TestVisible
    private virtual CartExtension.CreateOrderResponse callDefault(CartExtension.CreateOrderRequest request) {
        return super.createOrder(request);
    }
}