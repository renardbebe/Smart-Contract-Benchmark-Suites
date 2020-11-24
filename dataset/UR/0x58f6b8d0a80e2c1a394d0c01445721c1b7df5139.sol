 

pragma solidity ^0.4.15;

 



 
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


contract PizzaParlor {

  uint8 public constant FLIPPINESS = 64;
  uint8 public constant FLIPPINESSROUNDBONUS = 16;
  uint8 public constant MAXROUNDS = 12;  
  uint32 public constant BLOCKTIMEOUT = 40; 

  address public cryptogsAddress;
  function PizzaParlor(address _cryptogsAddress) public {
    cryptogsAddress=_cryptogsAddress;
  }

   
   
   
   
   
   
   
   
   

     
  mapping (bytes32 => mapping (address => bytes32)) public commitReceipt;

     
  mapping (bytes32 => mapping (address => uint32)) public commitBlock;

  mapping (bytes32 => uint8) public stacksTransferred;

   
   
  function onTransferStack(address _sender, uint _token1, uint _token2, uint _token3, uint _token4, uint _token5, bytes32 _commit){

     
    require(msg.sender == cryptogsAddress);

     
    require(commitReceipt[_commit][_sender] == 0);

     
    require(stacksTransferred[_commit]<2);
    stacksTransferred[_commit]++;

     
    NFT cryptogsContract = NFT(cryptogsAddress);
    require(cryptogsContract.tokenIndexToOwner(_token1)==address(this));
    require(cryptogsContract.tokenIndexToOwner(_token2)==address(this));
    require(cryptogsContract.tokenIndexToOwner(_token3)==address(this));
    require(cryptogsContract.tokenIndexToOwner(_token4)==address(this));
    require(cryptogsContract.tokenIndexToOwner(_token5)==address(this));

     
    bytes32 receipt = keccak256(_commit,_sender,_token1,_token2,_token3,_token4,_token5);
    commitReceipt[_commit][_sender] = receipt;
    commitBlock[_commit][_sender] = uint32(block.number);

     
    TransferStack(_commit,_sender,receipt,now,_token1,_token2,_token3,_token4,_token5);
  }
  event TransferStack(bytes32 indexed _commit,address indexed _sender,bytes32 indexed _receipt,uint _timestamp,uint256 _token1,uint256 _token2,uint256 _token3,uint256 _token4,uint256 _token5);

   
   
   
   
   
   
   
  function generateGame(bytes32 _commit,bytes32 _reveal,address _opponent,uint _token1, uint _token2, uint _token3, uint _token4, uint _token5,uint _token6, uint _token7, uint _token8, uint _token9, uint _token10){
     
    require( commitReceipt[_commit][msg.sender] == keccak256(_commit,msg.sender,_token1,_token2,_token3,_token4,_token5) );
    require( commitReceipt[_commit][_opponent] == keccak256(_commit,_opponent,_token6,_token7,_token8,_token9,_token10) );

     
    require( uint32(block.number) > commitBlock[_commit][msg.sender]);
    require( uint32(block.number) > commitBlock[_commit][_opponent]);

     
    require(_commit == keccak256(_reveal));

     
    require(stacksTransferred[_commit]==2);

    _generateGame(_commit,_reveal,_opponent,[_token1,_token2,_token3,_token4,_token5,_token6,_token7,_token8,_token9,_token10]);
  }

  function _generateGame(bytes32 _commit,bytes32 _reveal,address _opponent,uint[10] _tokens) internal {
     
    NFT cryptogsContract = NFT(cryptogsAddress);

     
    bytes32[4] memory pseudoRandoms = _generateRandom(_reveal,commitBlock[_commit][msg.sender],commitBlock[_commit][_opponent]);

    bool whosTurn = uint8(pseudoRandoms[0][0])%2==0;
    CoinFlip(_commit,whosTurn,whosTurn ? msg.sender : _opponent);
    for(uint8 round=1;round<=MAXROUNDS;round++){
      for(uint8 i=1;i<=10;i++){
         
        if(_tokens[i-1]>0){

           
          uint8 rand = _getRandom(pseudoRandoms,(round-1)*10 + i);

          uint8 threshold = (FLIPPINESS+round*FLIPPINESSROUNDBONUS);
          if( rand < threshold || round==MAXROUNDS ){
            _flip(_commit,round,cryptogsContract,_tokens,i-1,_opponent,whosTurn);
          }
        }
      }
      whosTurn = !whosTurn;
    }


    delete commitReceipt[_commit][msg.sender];
    delete commitReceipt[_commit][_opponent];

    GenerateGame(_commit,msg.sender);
  }
  event CoinFlip(bytes32 indexed _commit,bool _result,address _winner);
  event GenerateGame(bytes32 indexed _commit,address indexed _sender);

  function _getRandom(bytes32[4] pseudoRandoms,uint8 randIndex) internal returns (uint8 rand){
    if(randIndex<32){
      rand = uint8(pseudoRandoms[0][randIndex]);
    }else if(randIndex<64){
      rand = uint8(pseudoRandoms[1][randIndex-32]);
    }else if(randIndex<96){
      rand = uint8(pseudoRandoms[1][randIndex-64]);
    }else{
      rand = uint8(pseudoRandoms[1][randIndex-96]);
    }
    return rand;
  }

  function _generateRandom(bytes32 _reveal, uint32 block1,uint32 block2) internal returns(bytes32[4] pseudoRandoms){
    pseudoRandoms[0] = keccak256(_reveal,block.blockhash(max(block1,block2)));
    pseudoRandoms[1] = keccak256(pseudoRandoms[0]);
    pseudoRandoms[2] = keccak256(pseudoRandoms[1]);
    pseudoRandoms[3] = keccak256(pseudoRandoms[2]);
    return pseudoRandoms;
  }

  function max(uint32 a, uint32 b) private pure returns (uint32) {
      return a > b ? a : b;
  }

  function _flip(bytes32 _commit,uint8 round,NFT cryptogsContract,uint[10] _tokens,uint8 tokenIndex,address _opponent,bool whosTurn) internal {
    address flipper;
    if(whosTurn) {
      flipper=msg.sender;
    }else{
      flipper=_opponent;
    }
    cryptogsContract.transfer(flipper,_tokens[tokenIndex]);
    Flip(_commit,round,flipper,_tokens[tokenIndex]);
    _tokens[tokenIndex]=0;
  }
  event Flip(bytes32 indexed _commit,uint8 _round,address indexed _flipper,uint indexed _token);

   
   
   
   
  function drainGame(bytes32 _commit,bytes32 _secret,address _opponent,uint _token1, uint _token2, uint _token3, uint _token4, uint _token5,uint _token6, uint _token7, uint _token8, uint _token9, uint _token10){
     
    require( commitReceipt[_commit][msg.sender] == keccak256(_commit,msg.sender,_token1,_token2,_token3,_token4,_token5) );
    require( commitReceipt[_commit][_opponent] == keccak256(_commit,_opponent,_token6,_token7,_token8,_token9,_token10) );

     
    require( uint32(block.number) > commitBlock[_commit][msg.sender]+BLOCKTIMEOUT);
    require( uint32(block.number) > commitBlock[_commit][_opponent]+BLOCKTIMEOUT);

     
    require(_commit == keccak256(keccak256(_secret)));

     
    require(stacksTransferred[_commit]==2);

    _drainGame(_commit,_opponent,[_token1,_token2,_token3,_token4,_token5,_token6,_token7,_token8,_token9,_token10]);
  }

  function _drainGame(bytes32 _commit,address _opponent, uint[10] _tokens) internal {
     
    NFT cryptogsContract = NFT(cryptogsAddress);

    cryptogsContract.transfer(msg.sender,_tokens[0]);
    cryptogsContract.transfer(msg.sender,_tokens[1]);
    cryptogsContract.transfer(msg.sender,_tokens[2]);
    cryptogsContract.transfer(msg.sender,_tokens[3]);
    cryptogsContract.transfer(msg.sender,_tokens[4]);
    cryptogsContract.transfer(msg.sender,_tokens[5]);
    cryptogsContract.transfer(msg.sender,_tokens[6]);
    cryptogsContract.transfer(msg.sender,_tokens[7]);
    cryptogsContract.transfer(msg.sender,_tokens[8]);
    cryptogsContract.transfer(msg.sender,_tokens[9]);

    Flip(_commit,1,msg.sender,_tokens[0]);
    Flip(_commit,1,msg.sender,_tokens[1]);
    Flip(_commit,1,msg.sender,_tokens[2]);
    Flip(_commit,1,msg.sender,_tokens[3]);
    Flip(_commit,1,msg.sender,_tokens[4]);
    Flip(_commit,1,msg.sender,_tokens[5]);
    Flip(_commit,1,msg.sender,_tokens[6]);
    Flip(_commit,1,msg.sender,_tokens[7]);
    Flip(_commit,1,msg.sender,_tokens[8]);
    Flip(_commit,1,msg.sender,_tokens[9]);

    delete commitReceipt[_commit][msg.sender];
    delete commitReceipt[_commit][_opponent];
    DrainGame(_commit,msg.sender);
  }
  event DrainGame(bytes32 indexed _commit,address indexed _sender);

   
   
  function revokeStack(bytes32 _commit,uint _token1, uint _token2, uint _token3, uint _token4, uint _token5){
     
    require( commitReceipt[_commit][msg.sender] == keccak256(_commit,msg.sender,_token1,_token2,_token3,_token4,_token5) );

     
    require(stacksTransferred[_commit]==1);

    stacksTransferred[_commit]=0;

    NFT cryptogsContract = NFT(cryptogsAddress);

    cryptogsContract.transfer(msg.sender,_token1);
    cryptogsContract.transfer(msg.sender,_token2);
    cryptogsContract.transfer(msg.sender,_token3);
    cryptogsContract.transfer(msg.sender,_token4);
    cryptogsContract.transfer(msg.sender,_token5);


    bytes32 previousReceipt = commitReceipt[_commit][msg.sender];

    delete commitReceipt[_commit][msg.sender];
     
    RevokeStack(_commit,msg.sender,now,_token1,_token2,_token3,_token4,_token5,previousReceipt);
  }
  event RevokeStack(bytes32 indexed _commit,address indexed _sender,uint _timestamp,uint256 _token1,uint256 _token2,uint256 _token3,uint256 _token4,uint256 _token5,bytes32 _receipt);

}

contract NFT {
  function approve(address _to,uint256 _tokenId) public returns (bool) { }
  function transfer(address _to,uint256 _tokenId) external { }
  mapping (uint256 => address) public tokenIndexToOwner;
}