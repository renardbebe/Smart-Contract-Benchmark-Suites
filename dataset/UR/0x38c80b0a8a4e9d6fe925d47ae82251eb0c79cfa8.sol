 

pragma solidity ^0.4.21;

 
interface ERC20token {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract ExoTokensSwap{
    ERC20token TokenFrom;
    ERC20token TokenTo;
    uint256 FromDecimals;
    uint256 ToDecimals;
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        FromDecimals = 18;
        ToDecimals = 3;
    }

    function getFromDecimals() public view returns(uint256) {
        return FromDecimals;
    }
    function getToDecimals() public view returns(uint256) {
        return ToDecimals;
    }

    function setToDecimals(uint256 toDec) public onlyOwner {
        ToDecimals = toDec;
    }
    function setFromDecimals(uint256 fromDec) public onlyOwner {
        FromDecimals = fromDec;
    }

    function setERC20TokenFrom(address tokenAddr) public onlyOwner  {
        TokenFrom = ERC20token(tokenAddr);
    }

    function getERC20TokenFrom() public view returns(address) {
        return TokenFrom;
    }

    function setERC20TokenTo(address tokenAddr) public onlyOwner  {
        TokenTo = ERC20token(tokenAddr);
    }

    function getERC20TokenTo() public view returns(address) {
        return TokenTo;
    }
    function getERC20BalanceFrom() public view returns(uint256) {
        return TokenFrom.balanceOf(this);
    }
    function getERC20BalanceTo() public view returns(uint256) {
        return TokenTo.balanceOf(this);
    }
    function swapERC20Token(uint256 weiFromAmount) public {
        require(weiFromAmount > 0);
        require (TokenFrom.allowance(msg.sender, this) >= weiFromAmount * 10**FromDecimals);
        uint256 wallet_tokenTo_balance = TokenTo.balanceOf(this);
        require(wallet_tokenTo_balance >= weiFromAmount * 10**ToDecimals );  
        require(TokenFrom.transferFrom(msg.sender, this, weiFromAmount * 10**FromDecimals));  
        require(TokenTo.transfer(msg.sender, weiFromAmount * 10**ToDecimals));  
     }

    function moveERC20Tokens(address _tokenContract, address _to, uint _val) public onlyOwner {
        ERC20token token = ERC20token(_tokenContract);
        require(token.transfer(_to, _val));
    }

     
    function moveEther(address _target, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance);
        _target.transfer(_amount);
    }
         
    function setOwner(address _owner) public onlyOwner {
        owner = _owner;    
    }

     
    function() public payable{
    }

}