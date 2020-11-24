 

pragma solidity ^0.4.24;

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

contract WhitepaperVersioning {
    mapping (address => Whitepaper[]) private whitepapers;
    mapping (address => address) private authors;
    event Post(address indexed _contract, uint256 indexed _version, string _ipfsHash, address _author);

    struct Whitepaper {
        uint256 version;
        string ipfsHash;
    }

     
    constructor () public {}

     
    function pushWhitepaper (Ownable _contract, uint256 _version, string _ipfsHash) public returns (bool) {
        uint256 num = whitepapers[_contract].length;
        if(num == 0){
             
            require(_contract.owner() == msg.sender);
            authors[_contract] = msg.sender;
        }else{
             
            require(authors[_contract] == msg.sender);
             
            require(whitepapers[_contract][num-1].version < _version);
        }
    
        whitepapers[_contract].push(Whitepaper(_version, _ipfsHash));
        emit Post(_contract, _version, _ipfsHash, msg.sender);
        return true;
    }
  
     
    function getWhitepaperAt (address _contract, uint256 _index) public view returns (
        uint256 version,
        string ipfsHash,
        address author
    ) {
        return (
            whitepapers[_contract][_index].version,
            whitepapers[_contract][_index].ipfsHash,
            authors[_contract]
        );
    }
    
     
    function getLatestWhitepaper (address _contract) public view returns (
        uint256 version,
        string ipfsHash,
        address author
    ) {
        uint256 latest = whitepapers[_contract].length - 1;
        return getWhitepaperAt(_contract, latest);
    }
}