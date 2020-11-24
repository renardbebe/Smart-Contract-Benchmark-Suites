 

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
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
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
    function swapERC20Token(uint256 fromAmount) public returns(uint){
        require(fromAmount > 0);
        require (TokenFrom.allowance(msg.sender, this) >= fromAmount);
        uint256 wallet_tokenTo_balance = TokenTo.balanceOf(this);
        require(wallet_tokenTo_balance >= fromAmount);  
        require(TokenFrom.transferFrom(msg.sender, this, fromAmount));  
        require(TokenTo.transfer(msg.sender, fromAmount));  
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