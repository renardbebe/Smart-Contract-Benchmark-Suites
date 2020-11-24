 

pragma solidity ^0.4.24;

 
contract Ownable {
  address public owner;
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


   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract CFunIPBase is Ownable{

    struct Copyright 
    {
        uint256 copyrightID;
        string fingerprint; 
        string title;
        uint256 recordDate;
        address author;
        address recorder;

    }
    event Pause();
    event Unpause();
    event SaveCopyright(string fingerprint,string title,string author);

    Copyright[]  public copyrights;

    bool public paused = false;


    function saveCopyright(string fingerprint,string title,address author) public whenNotPaused {
        require(!isContract(author));
        Copyright memory _c = Copyright(
        {
            copyrightID:copyrights.length,
            fingerprint:fingerprint,
            title:title,
            recordDate:block.timestamp,
            author:author,
            recorder:msg.sender
        }
        );
        copyrights.push(_c);
        emit SaveCopyright(fingerprint,title,toString(author));

    }
    function copyrightCount() public  view  returns(uint256){
        return copyrights.length;

    }


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }

     
  function isContract(address _account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(_account) }
    return size > 0;
  }
  
    
  function toString(address _addr) private pure returns (string) {
      bytes memory b = new bytes(20);
      for (uint i = 0; i < 20; i++)
          b[i] = byte(uint8(uint(_addr) / (2**(8*(19 - i)))));
      return string(b);
  }

}