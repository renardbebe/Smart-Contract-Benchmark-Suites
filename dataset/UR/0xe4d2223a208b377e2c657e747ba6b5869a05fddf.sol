 

pragma solidity ^0.4.22;
contract Ownable {
     
  struct VowInfo {
      bytes32 tokenId; 
      string sign; 
      string content; 
      string time; 
  }
  mapping(bytes32 =>VowInfo) vowInfoToken;
  bytes32[] vowInfos;
     
    event NewMerchant(address sender,bool isScuccess,string message);
    function addVowInfo(bytes32 _tokenId,string sign,string content,string time) public {
        if(vowInfoToken[_tokenId].tokenId != _tokenId){
             vowInfoToken[_tokenId].tokenId = _tokenId;
              vowInfoToken[_tokenId].sign = sign;
              vowInfoToken[_tokenId].content = content;
              vowInfoToken[_tokenId].time = time;
              vowInfos.push(_tokenId);
              NewMerchant(msg.sender, true,"添加成功");
            return;
        }else{
             NewMerchant(msg.sender, false,"许愿ID已经存在");
            return;
        }
    }
      
    function getVowInfo(bytes32 _tokenId)public view returns(string tokenId,string sign,string content,string time){
                
         VowInfo memory vow = vowInfoToken[_tokenId];
        string memory vowId = bytes32ToString(vow.tokenId);
        return (vowId,vow.sign,vow.content,vow.time);
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