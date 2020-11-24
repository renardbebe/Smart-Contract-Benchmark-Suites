 

pragma solidity 0.4.21;

 

 
interface ExchangeHandler {

     
     
     
     
     
     
     
     
    function getAvailableAmount(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

     
     
     
     
     
     
     
     
     
    function performBuy(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (uint256);

     
     
     
     
     
     
     
     
     
    function performSell(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract Token is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 

contract TokenTransferProxy is Ownable {

     
    modifier onlyAuthorized {
        require(authorized[msg.sender]);
        _;
    }

    modifier targetAuthorized(address target) {
        require(authorized[target]);
        _;
    }

    modifier targetNotAuthorized(address target) {
        require(!authorized[target]);
        _;
    }

    mapping (address => bool) public authorized;
    address[] public authorities;

    event LogAuthorizedAddressAdded(address indexed target, address indexed caller);
    event LogAuthorizedAddressRemoved(address indexed target, address indexed caller);

     

     
     
    function addAuthorizedAddress(address target)
        public
        onlyOwner
        targetNotAuthorized(target)
    {
        authorized[target] = true;
        authorities.push(target);
        emit LogAuthorizedAddressAdded(target, msg.sender);
    }

     
     
    function removeAuthorizedAddress(address target)
        public
        onlyOwner
        targetAuthorized(target)
    {
        delete authorized[target];
        for (uint i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                authorities[i] = authorities[authorities.length - 1];
                authorities.length -= 1;
                break;
            }
        }
        emit LogAuthorizedAddressRemoved(target, msg.sender);
    }

     
     
     
     
     
     
    function transferFrom(
        address token,
        address from,
        address to,
        uint value)
        public
        onlyAuthorized
        returns (bool)
    {
        return Token(token).transferFrom(from, to, value);
    }

     

     
     
    function getAuthorizedAddresses()
        public
        constant
        returns (address[])
    {
        return authorities;
    }
}

 

 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract TotlePrimary is Ownable {
     
    uint256 public constant MAX_EXCHANGE_FEE_PERCENTAGE = 0.01 * 10**18;  
    bool constant BUY = false;
    bool constant SELL = true;

     
    mapping(address => bool) public handlerWhitelist;
    address tokenTransferProxy;

     
    struct Tokens {
        address[] tokenAddresses;
        bool[]    buyOrSell;
        uint256[] amountToObtain;
        uint256[] amountToGive;
    }

    struct DEXOrders {
        address[] tokenForOrder;
        address[] exchanges;
        address[8][] orderAddresses;
        uint256[6][] orderValues;
        uint256[] exchangeFees;
        uint8[] v;
        bytes32[] r;
        bytes32[] s;
    }

     
     
    function TotlePrimary(address proxy) public {
        tokenTransferProxy = proxy;
    }

     

     
     
     
     
    function setHandler(address handler, bool allowed) public onlyOwner {
        handlerWhitelist[handler] = allowed;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function executeOrders(
         
        address[] tokenAddresses,
        bool[]    buyOrSell,
        uint256[] amountToObtain,
        uint256[] amountToGive,
         
        address[] tokenForOrder,
        address[] exchanges,
        address[8][] orderAddresses,
        uint256[6][] orderValues,
        uint256[] exchangeFees,
        uint8[] v,
        bytes32[] r,
        bytes32[] s
    ) public payable {

        require(
            tokenAddresses.length == buyOrSell.length &&
            buyOrSell.length      == amountToObtain.length &&
            amountToObtain.length == amountToGive.length
        );

        require(
            tokenForOrder.length  == exchanges.length &&
            exchanges.length      == orderAddresses.length &&
            orderAddresses.length == orderValues.length &&
            orderValues.length    == exchangeFees.length &&
            exchangeFees.length   == v.length &&
            v.length              == r.length &&
            r.length              == s.length
        );

         
        internalOrderExecution(
            Tokens(
                tokenAddresses,
                buyOrSell,
                amountToObtain,
                amountToGive
            ),
            DEXOrders(
                tokenForOrder,
                exchanges,
                orderAddresses,
                orderValues,
                exchangeFees,
                v,
                r,
                s
            )
        );
    }

     

     
     
     
     
    function internalOrderExecution(Tokens tokens, DEXOrders orders) internal {
        transferTokens(tokens);

        uint256 tokensLength = tokens.tokenAddresses.length;
        uint256 ordersLength = orders.tokenForOrder.length;
        uint256 etherBalance = msg.value;
        uint256 orderIndex = 0;

        for(uint256 tokenIndex = 0; tokenIndex < tokensLength; tokenIndex++) {
             

            uint256 amountRemaining = tokens.amountToGive[tokenIndex];
            uint256 amountObtained = 0;

            while(orderIndex < ordersLength) {
                require(tokens.tokenAddresses[tokenIndex] == orders.tokenForOrder[orderIndex]);
                require(handlerWhitelist[orders.exchanges[orderIndex]]);

                if(amountRemaining > 0) {
                    if(tokens.buyOrSell[tokenIndex] == BUY) {
                        require(etherBalance >= amountRemaining);
                    }
                    (amountRemaining, amountObtained) = performTrade(
                        tokens.buyOrSell[tokenIndex],
                        amountRemaining,
                        amountObtained,
                        orders,  
                        orderIndex
                        );
                }

                orderIndex = SafeMath.add(orderIndex, 1);
                 
                if(orderIndex == ordersLength || orders.tokenForOrder[SafeMath.sub(orderIndex, 1)] != orders.tokenForOrder[orderIndex]){
                    break;
                }
            }

            uint256 amountGiven = SafeMath.sub(tokens.amountToGive[tokenIndex], amountRemaining);

            require(orderWasValid(amountObtained, amountGiven, tokens.amountToObtain[tokenIndex], tokens.amountToGive[tokenIndex]));

            if(tokens.buyOrSell[tokenIndex] == BUY) {
                 
                etherBalance = SafeMath.sub(etherBalance, amountGiven);
                 
                if(amountObtained > 0) {
                    require(Token(tokens.tokenAddresses[tokenIndex]).transfer(msg.sender, amountObtained));
                }
            } else {
                 
                etherBalance = SafeMath.add(etherBalance, amountObtained);
                 
                if(amountRemaining > 0) {
                    require(Token(tokens.tokenAddresses[tokenIndex]).transfer(msg.sender, amountRemaining));
                }
            }
        }

         
        if(etherBalance > 0) {
            msg.sender.transfer(etherBalance);
        }
    }

     
     
    function transferTokens(Tokens tokens) internal {
        uint256 expectedEtherAvailable = msg.value;
        uint256 totalEtherNeeded = 0;

        for(uint256 i = 0; i < tokens.tokenAddresses.length; i++) {
            if(tokens.buyOrSell[i] == BUY) {
                totalEtherNeeded = SafeMath.add(totalEtherNeeded, tokens.amountToGive[i]);
            } else {
                expectedEtherAvailable = SafeMath.add(expectedEtherAvailable, tokens.amountToObtain[i]);
                require(TokenTransferProxy(tokenTransferProxy).transferFrom(
                    tokens.tokenAddresses[i],
                    msg.sender,
                    this,
                    tokens.amountToGive[i]
                ));
            }
        }

         
        require(expectedEtherAvailable >= totalEtherNeeded);
    }

     
     
     
     
     
     
     
     
    function performTrade(bool buyOrSell, uint256 initialRemaining, uint256 totalObtained, DEXOrders orders, uint256 index)
        internal returns (uint256, uint256) {
        uint256 obtained = 0;
        uint256 remaining = initialRemaining;

        require(orders.exchangeFees[index] < MAX_EXCHANGE_FEE_PERCENTAGE);

        uint256 amountToFill = getAmountToFill(remaining, orders, index);

        if(amountToFill > 0) {
            remaining = SafeMath.sub(remaining, amountToFill);

            if(buyOrSell == BUY) {
                obtained = ExchangeHandler(orders.exchanges[index]).performBuy.value(amountToFill)(
                    orders.orderAddresses[index],
                    orders.orderValues[index],
                    orders.exchangeFees[index],
                    amountToFill,
                    orders.v[index],
                    orders.r[index],
                    orders.s[index]
                );
            } else {
                require(Token(orders.tokenForOrder[index]).transfer(
                    orders.exchanges[index],
                    amountToFill
                ));
                obtained = ExchangeHandler(orders.exchanges[index]).performSell(
                    orders.orderAddresses[index],
                    orders.orderValues[index],
                    orders.exchangeFees[index],
                    amountToFill,
                    orders.v[index],
                    orders.r[index],
                    orders.s[index]
                );
            }
        }

        return (obtained == 0 ? initialRemaining: remaining, SafeMath.add(totalObtained, obtained));
    }

     
     
     
     
     
    function getAmountToFill(uint256 remaining, DEXOrders orders, uint256 index) internal returns (uint256) {

        uint256 availableAmount = ExchangeHandler(orders.exchanges[index]).getAvailableAmount(
            orders.orderAddresses[index],
            orders.orderValues[index],
            orders.exchangeFees[index],
            orders.v[index],
            orders.r[index],
            orders.s[index]
        );

        return Math.min256(remaining, availableAmount);
    }

     
     
     
     
     
     
    function orderWasValid(uint256 amountObtained, uint256 amountGiven, uint256 amountToObtain, uint256 amountToGive) internal pure returns (bool) {

        if(amountObtained > 0 && amountGiven > 0) {
             
            if(amountObtained > amountGiven) {
                return SafeMath.div(amountToObtain, amountToGive) <= SafeMath.div(amountObtained, amountGiven);
            } else {
                return SafeMath.div(amountToGive, amountToObtain) >= SafeMath.div(amountGiven, amountObtained);
            }
        }
        return false;
    }

    function() public payable {
         
        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        require(size > 0);
    }
}