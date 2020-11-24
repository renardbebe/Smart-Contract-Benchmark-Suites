 

pragma solidity ^0.4.18;

contract ERC20 {
    function transfer(address _to, uint256 _value) public returns(bool);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Airdropper is Ownable {

    address public tokenAddr = 0x0;
    uint256 public numOfTokens;
    ERC20 public token;

    function Airdropper(address _tokenAddr, uint256 _numOfTokens) public {
        tokenAddr = _tokenAddr;
        numOfTokens = _numOfTokens;
        token = ERC20(_tokenAddr);
    }

    function multisend(address[] dests) public onlyOwner returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
           require(token.transfer(dests[i], numOfTokens));
           i += 1;
        }
        return(i);
    }

    function getLendTokenBalance() public constant returns (uint256) {
        return token.balanceOf(this);
    }

     
     
    function withdrawRemainingTokens() public onlyOwner  {
        uint contractTokenBalance = token.balanceOf(this);
        require(contractTokenBalance > 0);        
        token.transfer(owner, contractTokenBalance);
    }


     
    function withdrawERC20ToOwner(address _erc20) public onlyOwner {
        ERC20 erc20Token = ERC20(_erc20);
        uint contractTokenBalance = erc20Token.balanceOf(this);
        require(contractTokenBalance > 0);
        erc20Token.transfer(owner, contractTokenBalance);
    }

}