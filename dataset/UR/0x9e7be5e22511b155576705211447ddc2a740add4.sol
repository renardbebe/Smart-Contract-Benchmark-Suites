 

pragma solidity ^0.4.24;

 
 

 

contract Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
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


interface BancorConverter {
    function quickConvert(address[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
}

contract BancorHandler is ExchangeHandler {

     
    function getAvailableAmount(
        address[8] orderAddresses,  
        uint256[6] orderValues,  
        uint256 exchangeFee,  
        uint8 v,  
        bytes32 r,  
        bytes32 s  
    ) external returns (uint256) {
         
        return orderValues[0];
    }

    function performBuy(
        address[8] orderAddresses,  
        uint256[6] orderValues,  
        uint256 exchangeFee,  
        uint256 amountToFill,  
        uint8 v,  
        bytes32 r,  
        bytes32 s  
    ) external payable returns (uint256 amountObtained) {
        address destinationToken;
        (amountObtained, destinationToken) = trade(orderAddresses, orderValues);
        transferTokenToSender(destinationToken, amountObtained);
    }

    function performSell(
        address[8] orderAddresses,  
        uint256[6] orderValues,  
        uint256 exchangeFee,  
        uint256 amountToFill,  
        uint8 v,  
        bytes32 r,  
        bytes32 s  
    ) external returns (uint256 amountObtained) {
        approveExchange(orderAddresses[0], orderAddresses[1], orderValues[0]);
        (amountObtained, ) = trade(orderAddresses, orderValues);
        transferEtherToSender(amountObtained);
    }

    function trade(
        address[8] orderAddresses,  
        uint256[6] orderValues  
    ) internal returns (uint256 amountObtained, address destinationToken) {
         
        uint256 len;
        for(len = 1; len < orderAddresses.length; len++) {
            if(orderAddresses[len] == 0) {
                require(len > 1, "First element in conversion path was 0");
                destinationToken = orderAddresses[len - 1];
                len--;
                break;
            } else if(len == orderAddresses.length - 1) {
                destinationToken = orderAddresses[len];
                break;
            }
        }
         
        address[] memory conversionPath = new address[](len);

         
        for(uint256 i = 0; i < len; i++) {
            conversionPath[i] = orderAddresses[i + 1];
        }

        amountObtained = BancorConverter(orderAddresses[0])
                            .quickConvert.value(msg.value)(conversionPath, orderValues[0], orderValues[1]);
    }

    function transferTokenToSender(address token, uint256 amount) internal {
        Token(token).transfer(msg.sender, amount);
    }

    function transferEtherToSender(uint256 amount) internal {
        msg.sender.transfer(amount);
    }

    function approveExchange(address exchange, address token, uint256 amount) internal {
        Token(token).approve(exchange, amount);
    }

    function() public payable {
    }
}