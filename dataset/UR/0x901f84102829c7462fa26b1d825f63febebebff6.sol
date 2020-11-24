 

pragma solidity ^0.4.13;
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
}

contract PrivateCityToken {
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}


contract PrivateCityCrowdsale is SafeMath{

    uint256 public totalSupply;
     
    address public ethFundDeposit = 0x4574C2A0a1C39114Fe794dD1A3D1A5F90C92AD90;
    address public tokenExchangeAddress = 0xD9fc693CA2C5CF060D10E182a078a0A4CFF1F4d6;
    address public tokenAccountAddress = 0xdca42D3220681C3beaF3dD0631D06536c39beB67;
     
    PrivateCityToken public tokenExchange;

     
    enum ContractState { Fundraising }
    ContractState public state;

    uint256 public constant decimals = 18;
     
    uint public startDate = 1511510400;
     
    uint public endDate = 1514793600;
    
    uint256 public constant TOKEN_MIN = 1 * 10**decimals;  

     
    uint256 public totalReceivedEth = 0;
	

     
    function PrivateCityCrowdsale()
    {
         
        state = ContractState.Fundraising;
        tokenExchange = PrivateCityToken(tokenExchangeAddress);
        totalSupply = 0;
    }

    
    function ()
    payable
    external
    {
        require(now >= startDate);
        require(now <= endDate);
        require(msg.value > 0);
        

         
         
        uint256 checkedReceivedEth = safeAdd(totalReceivedEth, msg.value);

         
         
        uint256 tokens = safeMult(msg.value, getCurrentTokenPrice());
        require(tokens >= TOKEN_MIN);

        totalReceivedEth = checkedReceivedEth;
        totalSupply = safeAdd(totalSupply, tokens);
        ethFundDeposit.transfer(msg.value);
        if(!tokenExchange.transferFrom(tokenAccountAddress, msg.sender, tokens)) revert();
            

    }


     
    function getCurrentTokenPrice()
    private
    constant
    returns (uint256 currentPrice)
    {
        return 6000; 
    }

}