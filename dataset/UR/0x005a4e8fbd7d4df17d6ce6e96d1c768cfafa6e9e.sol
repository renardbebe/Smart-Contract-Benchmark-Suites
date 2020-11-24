 

pragma solidity ^0.5.0;


interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    function allocateTo(address recipient, uint256 value) external;
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract KyberNetworkProxyInterface {
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes memory hint) public payable returns(uint);

    function trade(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId) public payable returns(uint);

    function swapEtherToToken(ERC20 token, uint minConversionRate) external payable returns(uint);
    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external payable returns(uint);
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) public returns(uint);
}

 
 
contract KyberQuick {
    
    address public owner;
    address public tokenAddr;
    
     
    address constant KYBER_INTERFACE = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
    address constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    constructor(address _tokenAddr) public {
        owner = msg.sender;
        tokenAddr = _tokenAddr;
    }
    
    function() payable external {
        swapEtherToToken(msg.value, tokenAddr);
    }
    
    function swapEtherToToken (uint _ethAmount, address _tokenAddr) internal {
        uint minRate;
        ERC20 ETH_TOKEN_ADDRESS = ERC20(ETHER_ADDRESS);
        ERC20 token = ERC20(_tokenAddr);

        KyberNetworkProxyInterface _kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        (, minRate) = _kyberNetworkProxy.getExpectedRate(ETH_TOKEN_ADDRESS, token, _ethAmount);

        _kyberNetworkProxy.trade.value(_ethAmount)(
            ETH_TOKEN_ADDRESS,
            _ethAmount,
            token,
            msg.sender,
            uint(-1),
            minRate,
            owner
        );

    }
    
    
     
    function withdrawToken(address _tokenAddr, uint _amount) public {
        require(msg.sender == owner, "Must be the owner");
        
        ERC20(_tokenAddr).transfer(owner, _amount);
    }
    
    function withdrawEth(uint _amount) public {
        require(msg.sender == owner, "Must be the owner");
        
        msg.sender.transfer(_amount);
    }
}