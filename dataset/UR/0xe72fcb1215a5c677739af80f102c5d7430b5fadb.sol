 

pragma solidity ^0.4.19;

 
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

pragma solidity ^0.4.18;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract zombieToken {
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function transfer(address to, uint tokens) public returns (bool success);
  function buyCard(address from, uint256 value) public returns (bool success);
}

contract zombieMain {
  function createZombie(uint8 star,bytes32 dna,uint16 roletype,bool isFreeZombie,address player) public;
}

contract zombieCreator is Ownable {

  using SafeMath for uint256;

  event NewZombie(bytes32 dna, uint8 star,uint16 roletype, bool isfree);

  mapping (address => bool) isGetFreeZombie;

  uint createRandomZombie_EtherPrice = 0.01 ether;
  uint createRandomZombie_ZOBToken_smallpack = 100 * 10 ** 18;
  uint createRandomZombie_ZOBToken_goldpack = 400 * 10 ** 18;
  
  zombieMain c = zombieMain(0x58fd762F76D57C6fC2a480F6d26c1D03175AD64F);
  zombieToken t = zombieToken(0x83B8C8A08938B878017fDF0Ec0A689313F75739D);
  
  uint public FreeZombieCount = 999999;

  function isGetFreeZombiew(address _owner) public view returns (bool _getFreeZombie) {
    return isGetFreeZombie[_owner];
  }

  function createRandomZombie_ZOB_smallpack() public {

    require(t.buyCard(msg.sender, createRandomZombie_ZOBToken_smallpack));
    
    for(uint8 i = 0;i<3;i++){
       
       bytes32 dna;

       if(i == 0){
         dna = keccak256(block.blockhash(block.number-1), block.difficulty, block.coinbase, now, msg.sender, "CryptoDeads DNA Seed");
       } else if(i == 1){
         dna = keccak256(msg.sender, now, block.blockhash(block.number-1), "CryptoDeads DNA Seed", block.coinbase, block.difficulty);
       } else {
         dna = keccak256("CryptoDeads DNA Seed", now, block.difficulty, block.coinbase, block.blockhash(block.number-1), msg.sender);
       }

       uint star = uint(dna) % 1000 +1;
       uint roletype = 1;

       if(star<=700){
            star = 1;
            roletype = uint(keccak256(msg.sender ,block.blockhash(block.number-1), block.coinbase, now, block.difficulty)) % 3 + 1;
       }else if(star <= 980){
            star = 2;
            roletype = 4;
       }else{
            star = 3;
            roletype = uint(keccak256(block.blockhash(block.number-1), msg.sender, block.difficulty, block.coinbase, now)) % 3 + 5; 
       }

       c.createZombie(uint8(star),dna,uint16(roletype),false,msg.sender);
       NewZombie(dna,uint8(star),uint16(roletype),false);
    }
  }

  function createRandomZombie_ZOB_goldpack() public {

    require(t.buyCard(msg.sender, createRandomZombie_ZOBToken_goldpack));
    
    for(uint8 i = 0;i<3;i++){

       bytes32 dna;
       
       if(i == 0){
         dna = keccak256(block.blockhash(block.number-1), block.difficulty, block.coinbase, now, msg.sender, "CryptoDeads DNA Seed");
       } else if(i == 1){
         dna = keccak256(msg.sender, now, block.blockhash(block.number-1), "CryptoDeads DNA Seed", block.coinbase, block.difficulty);
       } else {
         dna = keccak256("CryptoDeads DNA Seed", now, block.difficulty, block.coinbase, block.blockhash(block.number-1), msg.sender);
       }

       uint star = uint(dna) % 1000 +1;
       uint roletype = 2;

       if(star<=700){
            star = 2;
            roletype = 4;
       }else if(star <= 950){
            star = 3;
            roletype = uint(keccak256(msg.sender ,block.blockhash(block.number-1), block.coinbase, now, block.difficulty)) % 3 + 5;
       }else{
            star = 4;
            roletype = uint(keccak256(block.blockhash(block.number-1), msg.sender, block.difficulty, block.coinbase, now)) % 3 + 9;
       }

       c.createZombie(uint8(star),dna,uint16(roletype),false,msg.sender);
       NewZombie(dna,uint8(star),uint16(roletype),false);
    }
  }

  function createRandomZombie_FreeZombie() public {
    require(!isGetFreeZombie[msg.sender]);
    require(FreeZombieCount>=1);

    uint ran = uint(keccak256(block.coinbase,block.difficulty,now, block.blockhash(block.number-1))) % 100 + 1;

    uint roletype = 1;
    uint8 star = 1;

    if(ran>=90){
      roletype = 2;
      star = 4;
    } else {
      roletype = uint(keccak256(msg.sender ,block.blockhash(block.number-1), block.coinbase, now, block.difficulty)) % 3 + 1;
    }
    
    bytes32 dna = keccak256(block.blockhash(block.number-1), block.difficulty, block.coinbase, now, msg.sender, "CryptoDeads DNA Seed");
    
    c.createZombie(star,dna,uint16(roletype),true,msg.sender);
    isGetFreeZombie[msg.sender] = true;
    FreeZombieCount--;

    NewZombie(dna,uint8(star),uint16(roletype),true);
  }
  
  function createRandomZombie_Ether() public payable{
    require(msg.value == createRandomZombie_EtherPrice);
    
    for(uint8 i = 0;i<3;i++){
       bytes32 dna;
       
       if(i == 0){
         dna = keccak256(block.blockhash(block.number-1), block.difficulty, block.coinbase, now, msg.sender, "CryptoDeads DNA Seed");
       } else if(i == 1){
         dna = keccak256(msg.sender, now, block.blockhash(block.number-1), "CryptoDeads DNA Seed", block.coinbase, block.difficulty);
       } else {
         dna = keccak256("CryptoDeads DNA Seed", now, block.difficulty, block.coinbase, block.blockhash(block.number-1), msg.sender);
       }

       uint star = uint(dna) % 1000 + 1;
       uint roletype = 4;

       if(star<=500){
            star = 2;
       }else if(star <= 850){
            star = 3;
            roletype = uint(keccak256(msg.sender ,block.blockhash(block.number-1), block.coinbase, now, block.difficulty)) % 4 + 5;
       }else{
            star = 4;
            roletype = uint(keccak256(block.blockhash(block.number-1), msg.sender, block.difficulty, block.coinbase, now)) % 4 + 9;
       } 

       c.createZombie(uint8(star),dna,uint16(roletype),false,msg.sender);
       
       NewZombie(dna,uint8(star),uint16(roletype),true);
    }
  }
  
  function changeFreeZombiewCount(uint16 _count) public onlyOwner {
      FreeZombieCount = _count;
  }
  
  function withdrawEther(uint _ether) public onlyOwner{
      msg.sender.transfer(_ether);
  }

  function withdrawZOB(uint _zob) public onlyOwner{
      t.transfer(msg.sender, _zob);
  }
}