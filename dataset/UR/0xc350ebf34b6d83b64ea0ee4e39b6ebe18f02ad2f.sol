 

 

pragma solidity ^0.4.8;

 
 

contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);

    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve( address spender, uint value ) returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract EventfulMarket {
    event ItemUpdate( uint id );
    event Trade( uint sell_how_much, address indexed sell_which_token,
                 uint buy_how_much, address indexed buy_which_token );

    event LogMake(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             haveToken,
        ERC20             wantToken,
        uint128           haveAmount,
        uint128           wantAmount,
        uint64            timestamp
    );

    event LogTake(
        bytes32           id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             haveToken,
        ERC20             wantToken,
        address  indexed  taker,
        uint128           takeAmount,
        uint128           giveAmount,
        uint64            timestamp
    );

    event LogKill(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             haveToken,
        ERC20             wantToken,
        uint128           haveAmount,
        uint128           wantAmount,
        uint64            timestamp
    );
}

contract SimpleMarket is EventfulMarket {
    bool locked;

    modifier synchronized {
        assert(!locked);
        locked = true;
        _;
        locked = false;
    }

    function assert(bool x) internal {
        if (!x) throw;
    }

    struct OfferInfo {
        uint     sell_how_much;
        ERC20    sell_which_token;
        uint     buy_how_much;
        ERC20    buy_which_token;
        address  owner;
        bool     active;
    }

    mapping (uint => OfferInfo) public offers;

    uint public last_offer_id;

    function next_id() internal returns (uint) {
        last_offer_id++; return last_offer_id;
    }

    modifier can_offer {
        _;
    }
    modifier can_buy(uint id) {
        assert(isActive(id));
        _;
    }
    modifier can_cancel(uint id) {
        assert(isActive(id));
        assert(getOwner(id) == msg.sender);
        _;
    }
    function isActive(uint id) constant returns (bool active) {
        return offers[id].active;
    }
    function getOwner(uint id) constant returns (address owner) {
        return offers[id].owner;
    }
    function getOffer( uint id ) constant returns (uint, ERC20, uint, ERC20) {
      var offer = offers[id];
      return (offer.sell_how_much, offer.sell_which_token,
              offer.buy_how_much, offer.buy_which_token);
    }

     
    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
     
    function safeMul(uint a, uint b) internal returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }

    function trade( address seller, uint sell_how_much, ERC20 sell_which_token,
                    address buyer,  uint buy_how_much,  ERC20 buy_which_token )
        internal
    {
        var seller_paid_out = buy_which_token.transferFrom( buyer, seller, buy_how_much );
        assert(seller_paid_out);
        var buyer_paid_out = sell_which_token.transfer( buyer, sell_how_much );
        assert(buyer_paid_out);
        Trade( sell_how_much, sell_which_token, buy_how_much, buy_which_token );
    }

     

    function make(
        ERC20    haveToken,
        ERC20    wantToken,
        uint128  haveAmount,
        uint128  wantAmount
    ) returns (bytes32 id) {
        return bytes32(offer(haveAmount, haveToken, wantAmount, wantToken));
    }

    function take(bytes32 id, uint128 maxTakeAmount) {
        assert(buy(uint256(id), maxTakeAmount));
    }

    function kill(bytes32 id) {
        assert(cancel(uint256(id)));
    }

     
    function offer( uint sell_how_much, ERC20 sell_which_token
                  , uint buy_how_much,  ERC20 buy_which_token )
        can_offer
        synchronized
        returns (uint id)
    {
        assert(uint128(sell_how_much) == sell_how_much);
        assert(uint128(buy_how_much) == buy_how_much);
        assert(sell_how_much > 0);
        assert(sell_which_token != ERC20(0x0));
        assert(buy_how_much > 0);
        assert(buy_which_token != ERC20(0x0));
        assert(sell_which_token != buy_which_token);

        OfferInfo memory info;
        info.sell_how_much = sell_how_much;
        info.sell_which_token = sell_which_token;
        info.buy_how_much = buy_how_much;
        info.buy_which_token = buy_which_token;
        info.owner = msg.sender;
        info.active = true;
        id = next_id();
        offers[id] = info;

        var seller_paid = sell_which_token.transferFrom( msg.sender, this, sell_how_much );
        assert(seller_paid);

        ItemUpdate(id);
        LogMake(
            bytes32(id),
            sha3(sell_which_token, buy_which_token),
            msg.sender,
            sell_which_token,
            buy_which_token,
            uint128(sell_how_much),
            uint128(buy_how_much),
            uint64(now)
        );
    }

     
     
    function buy( uint id, uint quantity )
        can_buy(id)
        synchronized
        returns ( bool success )
    {
        assert(uint128(quantity) == quantity);

         
        OfferInfo memory offer = offers[id];

         
        uint spend = safeMul(quantity, offer.buy_how_much) / offer.sell_how_much;
        assert(uint128(spend) == spend);

        if ( spend > offer.buy_how_much || quantity > offer.sell_how_much ) {
             
            success = false;
        } else if ( spend == offer.buy_how_much && quantity == offer.sell_how_much ) {
             
            delete offers[id];

            trade( offer.owner, quantity, offer.sell_which_token,
                   msg.sender, spend, offer.buy_which_token );

            ItemUpdate(id);
            LogTake(
                bytes32(id),
                sha3(offer.sell_which_token, offer.buy_which_token),
                offer.owner,
                offer.sell_which_token,
                offer.buy_which_token,
                msg.sender,
                uint128(offer.sell_how_much),
                uint128(offer.buy_how_much),
                uint64(now)
            );

            success = true;
        } else if ( spend > 0 && quantity > 0 ) {
             
            offers[id].sell_how_much = safeSub(offer.sell_how_much, quantity);
            offers[id].buy_how_much = safeSub(offer.buy_how_much, spend);

            trade( offer.owner, quantity, offer.sell_which_token,
                    msg.sender, spend, offer.buy_which_token );

            ItemUpdate(id);
            LogTake(
                bytes32(id),
                sha3(offer.sell_which_token, offer.buy_which_token),
                offer.owner,
                offer.sell_which_token,
                offer.buy_which_token,
                msg.sender,
                uint128(quantity),
                uint128(spend),
                uint64(now)
            );

            success = true;
        } else {
             
            success = false;
        }
    }

     
    function cancel( uint id )
        can_cancel(id)
        synchronized
        returns ( bool success )
    {
         
        OfferInfo memory offer = offers[id];
        delete offers[id];

        var seller_refunded = offer.sell_which_token.transfer( offer.owner , offer.sell_how_much );
        assert(seller_refunded);

        ItemUpdate(id);
        LogKill(
            bytes32(id),
            sha3(offer.sell_which_token, offer.buy_which_token),
            offer.owner,
            offer.sell_which_token,
            offer.buy_which_token,
            uint128(offer.sell_how_much),
            uint128(offer.buy_how_much),
            uint64(now)
        );

        success = true;
    }
}

 
 

contract ExpiringMarket is SimpleMarket {
    uint public lifetime;
    uint public close_time;

    function ExpiringMarket(uint lifetime_) {
        lifetime = lifetime_;
        close_time = getTime() + lifetime_;
    }

    function getTime() constant returns (uint) {
        return block.timestamp;
    }
    function isClosed() constant returns (bool closed) {
        return (getTime() > close_time);
    }

     
    modifier can_offer {
        assert(!isClosed());
        _;
    }
     
    modifier can_buy(uint id) {
        assert(isActive(id));
        assert(!isClosed());
        _;
    }
     
    modifier can_cancel(uint id) {
        assert(isActive(id));
        assert(isClosed() || (msg.sender == getOwner(id)));
        _;
    }
}