 

pragma solidity ^0.4.25;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract Scouting is Ownable {
    using SafeMath for uint32;
    
    struct TalentData {
        uint8 eventName;  
        string data;
    }
    struct TalentInfo {
        uint32 scoutId;
        uint8 numData;
        mapping (uint8 => TalentData) data;
    }
    mapping (uint32 => TalentInfo) talents;
    mapping (uint8 => string) eventNames;
    
    event playerSubmitted(
        uint32 indexed _talentId, 
        uint32 indexed _scoutId, 
        string _data
    );
    
    event playerAssessed(
        uint32 indexed _talentId, 
        uint32 indexed _scoutId, 
        string _data
    );
    
    event playerRejected(
        uint32 indexed _talentId, 
        uint32 indexed _scoutId, 
        string _data
    );
    
    event playerVotepro(
        uint32 indexed _talentId, 
        uint32 indexed _scoutId, 
        string _data
    );
    
    event playerVotecontra(
        uint32 indexed _talentId, 
        uint32 indexed _scoutId, 
        string _data
    );
    
    
    event playerSupportContracted(
        uint32 indexed _talentId, 
        uint32 indexed _scoutId, 
        string _data
    );
    
    constructor() public{
        eventNames[4] = "player_submitted";
        eventNames[5] = "player_assessed";
        eventNames[6] = "player_rejected";
        eventNames[9] = "player_votepro";
        eventNames[10] = "player_votecontra";
        eventNames[12] = "player_support_contracted";
    }
    
     
    function addTalent(uint32 talentId, uint32 scoutId, uint8 eventName, string data) public onlyOwner{
        if(eventName == 4 || eventName == 5 || eventName == 6 || eventName == 9 || eventName == 10 || eventName == 12){
            if(talents[talentId].scoutId == 0){
                talents[talentId] = TalentInfo(scoutId, 0);
                fillData(talentId, eventName, data);
            }
            else{
                fillData(talentId, eventName, data);
            }    
        }
    }
    
    function fillData(uint32 talentId, uint8 eventName, string data) private onlyOwner{
        TalentInfo storage ti = talents[talentId];
        ti.data[ti.numData++] =  TalentData(eventName, data);
        
         
        if(eventName == 4){
            emit playerSubmitted(talentId, ti.scoutId, data);
        }
        else{
            
            if(eventName == 5){   
                emit playerAssessed(talentId, ti.scoutId, data);
           }
           else{
               
              if(eventName == 6){
                emit playerRejected(talentId, ti.scoutId, data);
               }
               else{
                    
                   if(eventName == 9){
                    emit playerVotepro(talentId, ti.scoutId, data);
                   }
                   else{
                       
                        if(eventName == 10){  
                        emit playerVotecontra(talentId, ti.scoutId, data);
                       }
                       else{
                           
                          if(eventName == 12){  
                            emit playerSupportContracted(talentId, ti.scoutId, data);
                           }  
                       } 
                   } 
               }  
           } 
        }
    }
   
    
     
    function viewTalent(uint32 _talentId) public constant returns (uint talentId, uint scoutId, uint8 countRecords, string eventName, string data) {
        return (
            _talentId, 
            talents[_talentId].scoutId, 
            talents[_talentId].numData, 
            eventNames[talents[_talentId].data[talents[_talentId].numData-1].eventName], 
            talents[_talentId].data[talents[_talentId].numData-1].data
            );
    }
    
    function viewTalentNum(uint32 talentId, uint8 numData) public constant returns (uint _talentId, uint scoutId, string eventName, string data) {
        return (
            talentId, 
            talents[talentId].scoutId, 
            eventNames[talents[talentId].data[numData].eventName], 
            talents[talentId].data[numData].data
            );
    }
}