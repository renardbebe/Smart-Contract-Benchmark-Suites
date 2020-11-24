 

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
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
 

contract TokenLoot is Ownable {

   
   
  address neverdieSigner;
   
  ERC20 sklToken;
   
  ERC20 xpToken;
   
  ERC20 goldToken;
   
  ERC20 silverToken;
   
  ERC20 scaleToken;
   
  mapping (address => uint) public nonces;


   
  event ReceiveLoot(address indexed sender,
                    uint _amountSKL,
                    uint _amountXP,
                    uint _amountGold,
                    uint _amountSilver,
                    uint _amountScale,
                    uint _nonce);
 

   
  function setSKLContractAddress(address _to) public onlyOwner {
    sklToken = ERC20(_to);
  }

  function setXPContractAddress(address _to) public onlyOwner {
    xpToken = ERC20(_to);
  }

  function setGoldContractAddress(address _to) public onlyOwner {
    goldToken = ERC20(_to);
  }

  function setSilverContractAddress(address _to) public onlyOwner {
    silverToken = ERC20(_to);
  }

  function setScaleContractAddress(address _to) public onlyOwner {
    scaleToken = ERC20(_to);
  }

  function setNeverdieSignerAddress(address _to) public onlyOwner {
    neverdieSigner = _to;
  }

   
   
   
   
   
   
   
  function TokenLoot(address _xpContractAddress,
                     address _sklContractAddress,
                     address _goldContractAddress,
                     address _silverContractAddress,
                     address _scaleContractAddress,
                     address _signer) {
    xpToken = ERC20(_xpContractAddress);
    sklToken = ERC20(_sklContractAddress);
    goldToken = ERC20(_goldContractAddress);
    silverToken = ERC20(_silverContractAddress);
    scaleToken = ERC20(_scaleContractAddress);
    neverdieSigner = _signer;
  }

   
   
   
   
   
   
   
   
   
   
  function receiveTokenLoot(uint _amountSKL, 
                            uint _amountXP, 
                            uint _amountGold, 
                            uint _amountSilver,
                            uint _amountScale,
                            uint _nonce, 
                            uint8 _v, 
                            bytes32 _r, 
                            bytes32 _s) {

     
    require(_nonce > nonces[msg.sender]);
    nonces[msg.sender] = _nonce;

     
    address signer = ecrecover(keccak256(msg.sender, 
                                         _amountSKL, 
                                         _amountXP, 
                                         _amountGold,
                                         _amountSilver,
                                         _amountScale,
                                         _nonce), _v, _r, _s);
    require(signer == neverdieSigner);

     
    if (_amountSKL > 0) assert(sklToken.transfer(msg.sender, _amountSKL));
    if (_amountXP > 0) assert(xpToken.transfer(msg.sender, _amountXP));
    if (_amountGold > 0) assert(goldToken.transfer(msg.sender, _amountGold));
    if (_amountSilver > 0) assert(silverToken.transfer(msg.sender, _amountSilver));
    if (_amountScale > 0) assert(scaleToken.transfer(msg.sender, _amountScale));

     
    ReceiveLoot(msg.sender, _amountSKL, _amountXP, _amountGold, _amountSilver, _amountScale, _nonce);
  }

   
  function () payable public { 
      revert(); 
  }

   
  function withdraw() public onlyOwner {
    uint256 allSKL = sklToken.balanceOf(this);
    uint256 allXP = xpToken.balanceOf(this);
    uint256 allGold = goldToken.balanceOf(this);
    uint256 allSilver = silverToken.balanceOf(this);
    uint256 allScale = scaleToken.balanceOf(this);
    if (allSKL > 0) sklToken.transfer(msg.sender, allSKL);
    if (allXP > 0) xpToken.transfer(msg.sender, allXP);
    if (allGold > 0) goldToken.transfer(msg.sender, allGold);
    if (allSilver > 0) silverToken.transfer(msg.sender, allSilver);
    if (allScale > 0) scaleToken.transfer(msg.sender, allScale);
  }

   
  function kill() onlyOwner public {
    withdraw();
    selfdestruct(owner);
  }

}