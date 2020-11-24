 

pragma solidity ^0.4.22;
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract TokenMall is Ownable {
   
  struct MortgageInfo {
      bytes32 projectId; 
      string currency; 
      string mortgageAmount; 
      string releaseAmount; 
  }
  mapping(bytes32 =>MortgageInfo) mInfo;
  bytes32[] mortgageInfos;
   
   
    event MessageMintInfo(address sender,bool isScuccess,string message);
    function mintMortgageInfo(string _projectId,string currency,string mortgageAmount,string releaseAmount) onlyOwner{
        bytes32 proId = stringToBytes32(_projectId);
        if(mInfo[proId].projectId != proId){
              mInfo[proId].projectId = proId;
              mInfo[proId].currency = currency;
              mInfo[proId].mortgageAmount = mortgageAmount;
              mInfo[proId].releaseAmount = releaseAmount;
              mortgageInfos.push(proId);
              MessageMintInfo(msg.sender, true,"添加成功");
            return;
        }else{
             MessageMintInfo(msg.sender, false,"项目ID已经存在");
            return;
        }
    }
   
    event MessageUpdateInfo(address sender,bool isScuccess,string message);
    function updateMortgageInfo(string _projectId,string releaseAmount) onlyOwner{
         bytes32 proId = stringToBytes32(_projectId);
        if(mInfo[proId].projectId == proId){
              mInfo[proId].releaseAmount = releaseAmount;
              mortgageInfos.push(proId);
              MessageUpdateInfo(msg.sender, true,"修改成功");
            return;
        }else{
             MessageUpdateInfo(msg.sender, false,"项目ID不存在");
            return;
        }
    }
     
     
   
    function getMortgageInfo(string _projectId) 
    public view returns(string projectId,string currency,string mortgageAmount,string releaseAmount){
         
         bytes32 proId = stringToBytes32(_projectId);
         
         MortgageInfo memory mi = mInfo[proId];
        
        return (_projectId,mi.currency,mi.mortgageAmount,mi.releaseAmount);
    }
    
      
    function stringToBytes32(string memory source) constant internal returns(bytes32 result){
        assembly{
            result := mload(add(source,32))
        }
    }
     
    function bytes32ToString(bytes32 x) constant internal returns(string){
        bytes memory bytesString = new bytes(32);
        uint charCount = 0 ;
        for(uint j = 0 ; j<32;j++){
            byte char = byte(bytes32(uint(x) *2 **(8*j)));
            if(char !=0){
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for(j=0;j<charCount;j++){
            bytesStringTrimmed[j]=bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

}