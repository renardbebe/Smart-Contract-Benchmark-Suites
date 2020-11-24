 

pragma solidity ^0.4.18;


 
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

  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

}


contract GanaToken is ERC20Basic {

  function saleTransfer(address to, uint256 value) public returns (bool);

}


 
contract GanaTokenAirdropper is Ownable {

  GanaToken gana;

  event ClaimedGanaTokens();
  event ClaimedTokens(address _token, uint256 claimedBalance);

  function GanaTokenAirdropper(address _gana) public{
    gana = GanaToken(_gana);
  }

  function airdrop(address[] _addrs, uint256[] _values) public onlyOwner {
    require(_addrs.length == _values.length);

    for(uint256 i = 0; i < _addrs.length; i++) {
      require(gana.saleTransfer(_addrs[i], _values[i]));
    }
  }

  function claimGanaTokens() public onlyOwner {
    uint256 ganaBalance = gana.balanceOf(this);
    require(ganaBalance >= 0);

    gana.saleTransfer(owner, ganaBalance);
    emit ClaimedGanaTokens();
  }

  function claimTokens(address _token) public onlyOwner {
    ERC20Basic token = ERC20Basic(_token);
    uint256 tokenBalance = token.balanceOf(this);
    require(tokenBalance >= 0);

    token.transfer(owner, tokenBalance);
    emit ClaimedTokens(_token, tokenBalance);
  }

  function ganaBalance() public view returns (uint256){
    return gana.balanceOf(this);
  }

}