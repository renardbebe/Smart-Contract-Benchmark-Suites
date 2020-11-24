 

pragma solidity 0.4.25;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
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

 
contract Authorizable is Ownable {
    
    mapping(address => bool) public authorized;
    event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

     
    constructor() public {
        authorize(msg.sender);
    }

     
    modifier onlyAuthorized() {
        require(authorized[msg.sender]);
        _;
    }

     
    function authorize(address _address) public onlyOwner {
        require(!authorized[_address]);
        emit AuthorizationSet(_address, true);
        authorized[_address] = true;
    }
     
    function deauthorize(address _address) public onlyOwner {
        require(authorized[_address]);
        emit AuthorizationSet(_address, false);
        authorized[_address] = false;
    }
}

contract ZmineRandom is Authorizable {
    
    uint256 public counter = 0;
    mapping(uint256 => uint256) public randomResultMap;
    mapping(uint256 => uint256[]) public randomInputMap;
    
 
    function random(uint256 min, uint256 max, uint256 lotto) public onlyAuthorized  {
        
		require(min > 0);
        require(max > min);
         
        counter++;
        uint256 result = ((uint256(keccak256(abi.encodePacked(lotto))) 
                        + uint256(keccak256(abi.encodePacked(counter))) 
                        + uint256(keccak256(abi.encodePacked(block.difficulty)))
                        + uint256(keccak256(abi.encodePacked(block.number - 1)))
                    ) % (max-min+1)) - min;
        
        uint256[] memory array = new uint256[](5);
        array[0] = min;
        array[1] = max;
        array[2] = lotto;
        array[3] = block.difficulty;
        array[4] = block.number;
        randomInputMap[counter] = array;
         
        randomResultMap[counter] = result;
    }

    function checkHash(uint256 n) public pure returns (uint256){
        return uint256(keccak256(abi.encodePacked(n)));
    }
}