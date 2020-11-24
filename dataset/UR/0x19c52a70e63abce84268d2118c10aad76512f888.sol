 

pragma solidity ^0.4.18;

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external;  
    function transferFrom(address _from, address _to, uint _value) external;  
    function approve(address _spender, uint _value) external;  
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface BancorContract {
     
    function quickConvert(address[] _path, uint256 _amount, uint256 _minReturn)
        external
        payable
        returns (uint256);
}


contract TestBancorTrade {
    event Trade(uint256 srcAmount, uint256 destAmount);
    
     
    
    function trade(ERC20 src, BancorContract bancorTradingContract, address[] _path, uint256 _amount, uint256 _minReturn) {
         
        src.approve(bancorTradingContract, _amount);
        
        uint256 destAmount = bancorTradingContract.quickConvert(_path, _amount, _minReturn);
        
        Trade(_amount, destAmount);
    }
    
    function getBack() {
        msg.sender.transfer(this.balance);
    }
    
    function getBackBNB() {
        ERC20 src = ERC20(0xB8c77482e45F1F44dE1745F52C74426C631bDD52);
        src.transfer(msg.sender, src.balanceOf(this));
    }
    
    function getBackToken(ERC20 token) {
        token.transfer(msg.sender, token.balanceOf(this));
    }
    
     
    function () public payable {

    }
}