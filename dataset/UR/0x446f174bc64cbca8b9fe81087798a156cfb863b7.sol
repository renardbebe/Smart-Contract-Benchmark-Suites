 

pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

 
contract Voting2018 is Ownable {
    string public version = "1.0";

    struct File {
        string content;
        string contentTime;

        string md5;
        string sha256;
        string sha1;
        string hashTime;
    }

    File[13] public files;

    function setHashes(uint8 fileId, string _md5, string _sha256, string _sha1, string _time) public onlyOwner() {
        if (fileId < files.length) {
            bytes memory hashTimeEmptyTest = bytes(files[fileId].hashTime);  
            if (hashTimeEmptyTest.length == 0) {
                files[fileId].md5 = _md5;
                files[fileId].sha256 = _sha256;
                files[fileId].sha1 = _sha1;
                files[fileId].hashTime = _time;
            } 
        }
    }

    function setContent(uint8 fileId, string _content, string _time) public onlyOwner() {
        if (fileId < files.length) {
            bytes memory contentTimeEmptyTest = bytes(files[fileId].contentTime);  
            if (contentTimeEmptyTest.length == 0) {
                files[fileId].content = _content;
                files[fileId].contentTime = _time;
            } 
        }
    }

    function getFile(uint8 fileId) public view returns (string content, string contentTime, string _md5, string _sha256, string _sha1, string hashTime) {
        if (fileId < files.length) {
            return (files[fileId].content, files[fileId].contentTime, files[fileId].md5, files[fileId].sha256, files[fileId].sha1, files[fileId].hashTime);
        }

        return ("", "", "", "", "", "");
    }
}