 

pragma solidity ^0.4.18;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}

contract EventfulMarket {
    event LogItemUpdate(uint id);
    event LogTrade(uint pay_amt, address indexed pay_gem,
                   uint buy_amt, address indexed buy_gem);

    event LogMake(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event LogBump(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event LogTake(
        bytes32           id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        address  indexed  taker,
        uint128           take_amt,
        uint128           give_amt,
        uint64            timestamp
    );

    event LogKill(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );
}

contract SimpleMarket is EventfulMarket, DSMath {

    uint public last_offer_id;

    mapping (uint => OfferInfo) public offers;

    bool locked;

    struct OfferInfo {
        uint     pay_amt;
        ERC20    pay_gem;
        uint     buy_amt;
        ERC20    buy_gem;
        address  owner;
        uint64   timestamp;
    }

    modifier can_buy(uint id) {
        require(isActive(id));
        _;
    }

    modifier can_cancel(uint id) {
        require(isActive(id));
        require(getOwner(id) == msg.sender);
        _;
    }

    modifier can_offer {
        _;
    }

    modifier synchronized {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    function isActive(uint id) public constant returns (bool active) {
        return offers[id].timestamp > 0;
    }

    function getOwner(uint id) public constant returns (address owner) {
        return offers[id].owner;
    }

    function getOffer(uint id) public constant returns (uint, ERC20, uint, ERC20) {
      var offer = offers[id];
      return (offer.pay_amt, offer.pay_gem,
              offer.buy_amt, offer.buy_gem);
    }

     

    function bump(bytes32 id_)
        public
        can_buy(uint256(id_))
    {
        var id = uint256(id_);
        LogBump(
            id_,
            keccak256(offers[id].pay_gem, offers[id].buy_gem),
            offers[id].owner,
            offers[id].pay_gem,
            offers[id].buy_gem,
            uint128(offers[id].pay_amt),
            uint128(offers[id].buy_amt),
            offers[id].timestamp
        );
    }

     
     
    function buy(uint id, uint quantity)
        public
        can_buy(id)
        synchronized
        returns (bool)
    {
        OfferInfo memory offer = offers[id];
        uint spend = mul(quantity, offer.buy_amt) / offer.pay_amt;

        require(uint128(spend) == spend);
        require(uint128(quantity) == quantity);

         
        if (quantity == 0 || spend == 0 ||
            quantity > offer.pay_amt || spend > offer.buy_amt)
        {
            return false;
        }

        offers[id].pay_amt = sub(offer.pay_amt, quantity);
        offers[id].buy_amt = sub(offer.buy_amt, spend);
        require( offer.buy_gem.transferFrom(msg.sender, offer.owner, spend) );
        require( offer.pay_gem.transfer(msg.sender, quantity) );

        LogItemUpdate(id);
        LogTake(
            bytes32(id),
            keccak256(offer.pay_gem, offer.buy_gem),
            offer.owner,
            offer.pay_gem,
            offer.buy_gem,
            msg.sender,
            uint128(quantity),
            uint128(spend),
            uint64(now)
        );
        LogTrade(quantity, offer.pay_gem, spend, offer.buy_gem);

        if (offers[id].pay_amt == 0) {
          delete offers[id];
        }

        return true;
    }

     
    function cancel(uint id)
        public
        can_cancel(id)
        synchronized
        returns (bool success)
    {
         
        OfferInfo memory offer = offers[id];
        delete offers[id];

        require( offer.pay_gem.transfer(offer.owner, offer.pay_amt) );

        LogItemUpdate(id);
        LogKill(
            bytes32(id),
            keccak256(offer.pay_gem, offer.buy_gem),
            offer.owner,
            offer.pay_gem,
            offer.buy_gem,
            uint128(offer.pay_amt),
            uint128(offer.buy_amt),
            uint64(now)
        );

        success = true;
    }

    function kill(bytes32 id)
        public
    {
        require(cancel(uint256(id)));
    }

    function make(
        ERC20    pay_gem,
        ERC20    buy_gem,
        uint128  pay_amt,
        uint128  buy_amt
    )
        public
        returns (bytes32 id)
    {
        return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem));
    }

     
    function offer(uint pay_amt, ERC20 pay_gem, uint buy_amt, ERC20 buy_gem)
        public
        can_offer
        synchronized
        returns (uint id)
    {
        require(uint128(pay_amt) == pay_amt);
        require(uint128(buy_amt) == buy_amt);
        require(pay_amt > 0);
        require(pay_gem != ERC20(0x0));
        require(buy_amt > 0);
        require(buy_gem != ERC20(0x0));
        require(pay_gem != buy_gem);

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
        info.owner = msg.sender;
        info.timestamp = uint64(now);
        id = _next_id();
        offers[id] = info;

        require( pay_gem.transferFrom(msg.sender, this, pay_amt) );

        LogItemUpdate(id);
        LogMake(
            bytes32(id),
            keccak256(pay_gem, buy_gem),
            msg.sender,
            pay_gem,
            buy_gem,
            uint128(pay_amt),
            uint128(buy_amt),
            uint64(now)
        );
    }

    function take(bytes32 id, uint128 maxTakeAmount)
        public
    {
        require(buy(uint256(id), maxTakeAmount));
    }

    function _next_id()
        internal
        returns (uint)
    {
        last_offer_id++; return last_offer_id;
    }
}

 
 

contract ExpiringMarket is DSAuth, SimpleMarket {
    uint64 public close_time;
    bool public stopped;

     
    modifier can_offer {
        require(!isClosed());
        _;
    }

     
    modifier can_buy(uint id) {
        require(isActive(id));
        require(!isClosed());
        _;
    }

     
    modifier can_cancel(uint id) {
        require(isActive(id));
        require(isClosed() || (msg.sender == getOwner(id)));
        _;
    }

    function ExpiringMarket(uint64 _close_time)
        public
    {
        close_time = _close_time;
    }

    function isClosed() public constant returns (bool closed) {
        return stopped || getTime() > close_time;
    }

    function getTime() public constant returns (uint64) {
        return uint64(now);
    }

    function stop() public auth {
        stopped = true;
    }
}

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract MatchingEvents {
    event LogBuyEnabled(bool isEnabled);
    event LogMinSell(address pay_gem, uint min_amount);
    event LogMatchingEnabled(bool isEnabled);
    event LogUnsortedOffer(uint id);
    event LogSortedOffer(uint id);
    event LogAddTokenPairWhitelist(ERC20 baseToken, ERC20 quoteToken);
    event LogRemTokenPairWhitelist(ERC20 baseToken, ERC20 quoteToken);
    event LogInsert(address keeper, uint id);
    event LogDelete(address keeper, uint id);
}

contract MatchingMarket is MatchingEvents, ExpiringMarket, DSNote {
    bool public buyEnabled = true;       
    bool public matchingEnabled = true;  
                                          
    struct sortInfo {
        uint next;   
        uint prev;   
        uint delb;   
    }
    mapping(uint => sortInfo) public _rank;                      
    mapping(address => mapping(address => uint)) public _best;   
    mapping(address => mapping(address => uint)) public _span;   
    mapping(address => uint) public _dust;                       
    mapping(uint => uint) public _near;          
    mapping(bytes32 => bool) public _menu;       
    uint _head;                                  

     
    modifier isWhitelist(ERC20 buy_gem, ERC20 pay_gem) {
        require(_menu[keccak256(buy_gem, pay_gem)] || _menu[keccak256(pay_gem, buy_gem)]);
        _;
    }

    function MatchingMarket(uint64 close_time) ExpiringMarket(close_time) public {
    }

     

    function make(
        ERC20    pay_gem,
        ERC20    buy_gem,
        uint128  pay_amt,
        uint128  buy_amt
    )
        public
        returns (bytes32)
    {
        return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem));
    }

    function take(bytes32 id, uint128 maxTakeAmount) public {
        require(buy(uint256(id), maxTakeAmount));
    }

    function kill(bytes32 id) public {
        require(cancel(uint256(id)));
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function offer(
        uint pay_amt,     
        ERC20 pay_gem,    
        uint buy_amt,     
        ERC20 buy_gem     
    )
        public
        isWhitelist(pay_gem, buy_gem)
         
        returns (uint)
    {
        var fn = matchingEnabled ? _offeru : super.offer;
        return fn(pay_amt, pay_gem, buy_amt, buy_gem);
    }

     
    function offer(
        uint pay_amt,     
        ERC20 pay_gem,    
        uint buy_amt,     
        ERC20 buy_gem,    
        uint pos          
    )
        public
        isWhitelist(pay_gem, buy_gem)
         
        can_offer
        returns (uint)
    {
        return offer(pay_amt, pay_gem, buy_amt, buy_gem, pos, false);
    }

    function offer(
        uint pay_amt,     
        ERC20 pay_gem,    
        uint buy_amt,     
        ERC20 buy_gem,    
        uint pos,         
        bool rounding     
    )
        public
        isWhitelist(pay_gem, buy_gem)
         
        can_offer
        returns (uint)
    {
        require(_dust[pay_gem] <= pay_amt);

        if (matchingEnabled) {
          return _matcho(pay_amt, pay_gem, buy_amt, buy_gem, pos, rounding);
        }
        return super.offer(pay_amt, pay_gem, buy_amt, buy_gem);
    }

     
    function buy(uint id, uint amount)
        public
         
        can_buy(id)
        returns (bool)
    {
        var fn = matchingEnabled ? _buys : super.buy;
        return fn(id, amount);
    }

     
    function cancel(uint id)
        public
         
        can_cancel(id)
        returns (bool success)
    {
        if (matchingEnabled) {
            if (isOfferSorted(id)) {
                require(_unsort(id));
            } else {
                require(_hide(id));
            }
        }
        return super.cancel(id);     
    }

     
     
    function insert(
        uint id,    
        uint pos    
    )
        public
        returns (bool)
    {
        require(!isOfferSorted(id));     
        require(isActive(id));           

        _hide(id);                       
        _sort(id, pos);                  
        LogInsert(msg.sender, id);
        return true;
    }

     
     
    function del_rank(uint id)
        public
    returns (bool)
    {
        require(!isActive(id) && _rank[id].delb != 0 && _rank[id].delb < block.number - 10);
        delete _rank[id];
        LogDelete(msg.sender, id);
        return true;
    }

     
     
     
    function addTokenPairWhitelist(
        ERC20 baseToken,
        ERC20 quoteToken
    )
        public
        auth
        note
    returns (bool)
    {
        require(!isTokenPairWhitelisted(baseToken, quoteToken));
        require(address(baseToken) != 0x0 && address(quoteToken) != 0x0);

        _menu[keccak256(baseToken, quoteToken)] = true;
        LogAddTokenPairWhitelist(baseToken, quoteToken);
        return true;
    }

     
     
     
    function remTokenPairWhitelist(
        ERC20 baseToken,
        ERC20 quoteToken
    )
        public
        auth
        note
    returns (bool)
    {
        require(isTokenPairWhitelisted(baseToken, quoteToken));

        delete _menu[keccak256(baseToken, quoteToken)];
        delete _menu[keccak256(quoteToken, baseToken)];
        LogRemTokenPairWhitelist(baseToken, quoteToken);
        return true;
    }

    function isTokenPairWhitelisted(
        ERC20 baseToken,
        ERC20 quoteToken
    )
        public
        constant
        returns (bool)
    {
        return (_menu[keccak256(baseToken, quoteToken)] || _menu[keccak256(quoteToken, baseToken)]);
    }

     
     
     
     
     
    function setMinSell(
        ERC20 pay_gem,      
        uint dust           
    )
        public
        auth
        note
        returns (bool)
    {
        _dust[pay_gem] = dust;
        LogMinSell(pay_gem, dust);
        return true;
    }

     
    function getMinSell(
        ERC20 pay_gem       
    )
        public
        constant
        returns (uint)
    {
        return _dust[pay_gem];
    }

     
    function setBuyEnabled(bool buyEnabled_) public auth returns (bool) {
        buyEnabled = buyEnabled_;
        LogBuyEnabled(buyEnabled);
        return true;
    }

     
     
     
     
     
     
     
    function setMatchingEnabled(bool matchingEnabled_) public auth returns (bool) {
        matchingEnabled = matchingEnabled_;
        LogMatchingEnabled(matchingEnabled);
        return true;
    }

     
     
     
    function getBestOffer(ERC20 sell_gem, ERC20 buy_gem) public constant returns(uint) {
        return _best[sell_gem][buy_gem];
    }

     
     
     
     
    function getWorseOffer(uint id) public constant returns(uint) {
        return _rank[id].prev;
    }

     
     
     
     
    function getBetterOffer(uint id) public constant returns(uint) {

        return _rank[id].next;
    }

     
    function getOfferCount(ERC20 sell_gem, ERC20 buy_gem) public constant returns(uint) {
        return _span[sell_gem][buy_gem];
    }

     
     
     
     
     
    function getFirstUnsortedOffer() public constant returns(uint) {
        return _head;
    }

     
     
    function getNextUnsortedOffer(uint id) public constant returns(uint) {
        return _near[id];
    }

    function isOfferSorted(uint id) public constant returns(bool) {
        return _rank[id].next != 0
               || _rank[id].prev != 0
               || _best[offers[id].pay_gem][offers[id].buy_gem] == id;
    }

    function sellAllAmount(ERC20 pay_gem, uint pay_amt, ERC20 buy_gem, uint min_fill_amount)
        public
        returns (uint fill_amt)
    {
        uint offerId;
        while (pay_amt > 0) {                            
            offerId = getBestOffer(buy_gem, pay_gem);    
            require(offerId != 0);                       

             
            if (pay_amt * 1 ether < wdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) {
                break;                                   
            }
            if (pay_amt >= offers[offerId].buy_amt) {                        
                fill_amt = add(fill_amt, offers[offerId].pay_amt);           
                pay_amt = sub(pay_amt, offers[offerId].buy_amt);             
                take(bytes32(offerId), uint128(offers[offerId].pay_amt));    
            } else {  
                var baux = rmul(pay_amt * 10 ** 9, rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) / 10 ** 9;
                fill_amt = add(fill_amt, baux);          
                take(bytes32(offerId), uint128(baux));   
                pay_amt = 0;                             
            }
        }
        require(fill_amt >= min_fill_amount);
    }

    function buyAllAmount(ERC20 buy_gem, uint buy_amt, ERC20 pay_gem, uint max_fill_amount)
        public
        returns (uint fill_amt)
    {
        uint offerId;
        while (buy_amt > 0) {                            
            offerId = getBestOffer(buy_gem, pay_gem);    
            require(offerId != 0);

             
            if (buy_amt * 1 ether < wdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) {
                break;                                   
            }
            if (buy_amt >= offers[offerId].pay_amt) {                        
                fill_amt = add(fill_amt, offers[offerId].buy_amt);           
                buy_amt = sub(buy_amt, offers[offerId].pay_amt);             
                take(bytes32(offerId), uint128(offers[offerId].pay_amt));    
            } else {                                                         
                fill_amt = add(fill_amt, rmul(buy_amt * 10 ** 9, rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) / 10 ** 9);  
                take(bytes32(offerId), uint128(buy_amt));                    
                buy_amt = 0;                                                 
            }
        }
        require(fill_amt <= max_fill_amount);
    }

    function getBuyAmount(ERC20 buy_gem, ERC20 pay_gem, uint pay_amt) public constant returns (uint fill_amt) {
        var offerId = getBestOffer(buy_gem, pay_gem);            
        while (pay_amt > offers[offerId].buy_amt) {
            fill_amt = add(fill_amt, offers[offerId].pay_amt);   
            pay_amt = sub(pay_amt, offers[offerId].buy_amt);     
            if (pay_amt > 0) {                                   
                offerId = getWorseOffer(offerId);                
                require(offerId != 0);                           
            }
        }
        fill_amt = add(fill_amt, rmul(pay_amt * 10 ** 9, rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) / 10 ** 9);  
    }

    function getPayAmount(ERC20 pay_gem, ERC20 buy_gem, uint buy_amt) public constant returns (uint fill_amt) {
        var offerId = getBestOffer(buy_gem, pay_gem);            
        while (buy_amt > offers[offerId].pay_amt) {
            fill_amt = add(fill_amt, offers[offerId].buy_amt);   
            buy_amt = sub(buy_amt, offers[offerId].pay_amt);     
            if (buy_amt > 0) {                                   
                offerId = getWorseOffer(offerId);                
                require(offerId != 0);                           
            }
        }
        fill_amt = add(fill_amt, rmul(buy_amt * 10 ** 9, rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) / 10 ** 9);  
    }

     

    function _buys(uint id, uint amount)
        internal
        returns (bool)
    {
        require(buyEnabled);

        if (amount == offers[id].pay_amt && isOfferSorted(id)) {
             
            _unsort(id);
        }
        require(super.buy(id, amount));
        return true;
    }

     
    function _find(uint id)
        internal
        view
        returns (uint)
    {
        require( id > 0 );

        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        uint top = _best[pay_gem][buy_gem];
        uint old_top = 0;

         
        while (top != 0 && _isPricedLtOrEq(id, top)) {
            old_top = top;
            top = _rank[top].prev;
        }
        return old_top;
    }

     
    function _findpos(uint id, uint pos)
        internal
        view
    returns (uint)
    {
        require(id > 0);

         
        while (pos != 0 && !isActive(pos)) {
            pos = _rank[pos].prev;
        }

        if (pos == 0) {
             
            return _find(id);

        } else {
             
             
            if(_isPricedLtOrEq(id, pos)) {
                uint old_pos;

                 
                 
                while (pos != 0 && _isPricedLtOrEq(id, pos)) {
                    old_pos = pos;
                    pos = _rank[pos].prev;
                }
                return old_pos;

             
            } else {
                while (pos != 0 && !_isPricedLtOrEq(id, pos)) {
                    pos = _rank[pos].next;
                }
                return pos;
            }
        }
    }

     
    function _isPricedLtOrEq(
        uint low,    
        uint high    
    )
        internal
        view
        returns (bool)
    {
        return mul(offers[low].buy_amt, offers[high].pay_amt)
          >= mul(offers[high].buy_amt, offers[low].pay_amt);
    }

     

     
    function _matcho(
        uint t_pay_amt,     
        ERC20 t_pay_gem,    
        uint t_buy_amt,     
        ERC20 t_buy_gem,    
        uint pos,           
        bool rounding       
    )
        internal
        returns (uint id)
    {
        uint best_maker_id;     
        uint t_buy_amt_old;     
        uint m_buy_amt;         
        uint m_pay_amt;         

         
        while (_best[t_buy_gem][t_pay_gem] > 0) {
            best_maker_id = _best[t_buy_gem][t_pay_gem];
            m_buy_amt = offers[best_maker_id].buy_amt;
            m_pay_amt = offers[best_maker_id].pay_amt;

             
             
             
             
             
             
            if (mul(m_buy_amt, t_buy_amt) > mul(t_pay_amt, m_pay_amt) +
                (rounding ? m_buy_amt + t_buy_amt + t_pay_amt + m_pay_amt : 0))
            {
                break;
            }
             
             

            buy(best_maker_id, min(m_pay_amt, t_buy_amt));
            t_buy_amt_old = t_buy_amt;
            t_buy_amt = sub(t_buy_amt, min(m_pay_amt, t_buy_amt));
            t_pay_amt = mul(t_buy_amt, t_pay_amt) / t_buy_amt_old;

            if (t_pay_amt == 0 || t_buy_amt == 0) {
                break;
            }
        }

        if (t_buy_amt > 0 && t_pay_amt > 0) {
             
            id = super.offer(t_pay_amt, t_pay_gem, t_buy_amt, t_buy_gem);
             
            _sort(id, pos);
        }
    }

     
     
     
     
    function _offeru(
        uint pay_amt,       
        ERC20 pay_gem,      
        uint buy_amt,       
        ERC20 buy_gem       
    )
        internal
         
        returns (uint id)
    {
        require(_dust[pay_gem] <= pay_amt);
        id = super.offer(pay_amt, pay_gem, buy_amt, buy_gem);
        _near[id] = _head;
        _head = id;
        LogUnsortedOffer(id);
    }

     
    function _sort(
        uint id,     
        uint pos     
    )
        internal
    {
        require(isActive(id));

        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        uint prev_id;                                       

        if (pos == 0 || !isOfferSorted(pos)) {
            pos = _find(id);
        } else {
            pos = _findpos(id, pos);

             
             
            if(pos != 0 && (offers[pos].pay_gem != offers[id].pay_gem
                      || offers[pos].buy_gem != offers[id].buy_gem))
            {
                pos = 0;
                pos=_find(id);
            }
        }


         
         


        if (pos != 0) {                                     
             
             
            prev_id = _rank[pos].prev;
            _rank[pos].prev = id;
            _rank[id].next = pos;
        } else {                                            
            prev_id = _best[pay_gem][buy_gem];
            _best[pay_gem][buy_gem] = id;
        }

        if (prev_id != 0) {                                
             
             
            _rank[prev_id].next = id;
            _rank[id].prev = prev_id;
        }

        _span[pay_gem][buy_gem]++;
        LogSortedOffer(id);
    }

     
    function _unsort(
        uint id     
    )
        internal
        returns (bool)
    {
        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        require(_span[pay_gem][buy_gem] > 0);

        require(_rank[id].delb == 0 &&                     
                 isOfferSorted(id));

        if (id != _best[pay_gem][buy_gem]) {               
            require(_rank[_rank[id].next].prev == id);
            _rank[_rank[id].next].prev = _rank[id].prev;
        } else {                                           
            _best[pay_gem][buy_gem] = _rank[id].prev;
        }

        if (_rank[id].prev != 0) {                         
            require(_rank[_rank[id].prev].next == id);
            _rank[_rank[id].prev].next = _rank[id].next;
        }

        _span[pay_gem][buy_gem]--;
        _rank[id].delb = block.number;                     
        return true;
    }

     
    function _hide(
        uint id      
    )
        internal
        returns (bool)
    {
        uint uid = _head;                
        uint pre = uid;                  

        require(!isOfferSorted(id));     

        if (_head == id) {               
            _head = _near[id];           
            _near[id] = 0;               
            return true;
        }
        while (uid > 0 && uid != id) {   
            pre = uid;
            uid = _near[uid];
        }
        if (uid != id) {                 
            return false;
        }
        _near[pre] = _near[id];          
        _near[id] = 0;                   
        return true;
    }
}