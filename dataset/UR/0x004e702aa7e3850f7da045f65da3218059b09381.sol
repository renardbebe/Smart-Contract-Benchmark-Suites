 

pragma solidity ^0.4.24;

 
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

 

contract PixelStorage is Ownable{

    uint32[] coordinates;
    uint32[] rgba;
    address[] owners;
    uint256[] prices;

     
    uint32 public pixelCount;

     
     
     
     
     
     

    mapping(uint32 => uint32) coordinatesToIndex;

    constructor () public
    {
        pixelCount = 0;
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function withdraw() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }
    
    function buyPixel(uint16 _x, uint16 _y, uint32 _rgba) public payable {

        require(0 <= _x && _x < 0x200, "X should be in range 0-511");
        require(0 <= _y && _y < 0x200, "Y should be in range 0-511");

        uint32 coordinate = uint32(_x) << 16 | _y;
        uint32 index = coordinatesToIndex[coordinate];
        if(index == 0)
        {
             
             
            require(msg.value >= 1 finney, "Send atleast one finney!");
            
             
            pixelCount += 1;
             
            coordinatesToIndex[coordinate] = pixelCount;
            
             
            coordinates.push(coordinate);
            rgba.push(_rgba);
            prices.push(msg.value);
            owners.push(msg.sender);
        }
        else
        {
             
            require(msg.value >= prices[index-1] + 1 finney , "Insufficient funds send(atleast price + 1 finney)!");
            prices[index-1] = msg.value;
            owners[index-1] = msg.sender;
            rgba[index-1] = _rgba;
        }
        
    }
    
    
    function getPixels() public view returns (uint32[],  uint32[], address[],uint256[]) {
        return (coordinates,rgba,owners,prices);
    }
    
    function getPixel(uint16 _x, uint16 _y) public view returns (uint32, address, uint256){
        uint32 coordinate = uint32(_x) << 16 | _y;
        uint32 index = coordinatesToIndex[coordinate];
        if(index == 0){
            return (0, address(0x0), 0);
        }else{
            return (
                rgba[index-1], 
                owners[index-1],
                prices[index-1]
            );
        }
    }
}