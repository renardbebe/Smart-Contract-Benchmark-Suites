 

pragma solidity ^0.4.18;
 

 
interface TulipsSaleInterface {
    function putOnInitialSale(uint256 tulipId) external;
    function createAuction(
        uint256 _tulipId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _transferFrom
    )external;
}

 

 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
}

 

 
 
contract ERC721Metadata {
     
    function getMetadata(uint256 _tokenId, string) public view returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}

 

 
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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

 
contract TulipsRoles is Pausable {

    modifier onlyFinancial() {
        require(msg.sender == address(financialAccount));
        _;
    }

    modifier onlyOperations() {
        require(msg.sender == address(operationsAccount));
        _;
    }

    function TulipsRoles() Ownable() public {
        financialAccount = msg.sender;
        operationsAccount = msg.sender;
    }

    address public financialAccount;
    address public operationsAccount;

    function transferFinancial(address newFinancial) public onlyOwner {
        require(newFinancial != address(0));
        financialAccount = newFinancial;
    }

    function transferOperations(address newOperations) public onlyOwner {
        require(newOperations != address(0));
        operationsAccount = newOperations;
    }

}

 

contract TulipsStorage is TulipsRoles {

     

     
    struct Tulip {
        uint256 visualInfo;
        bytes32 visualHash;
    }

     
     
    Tulip[] public tulips;

     
    mapping (uint256 => address) public tulipIdToOwner;

     
    mapping (address => uint256) tulipOwnershipCount;

     
    mapping (uint256 => address) public tulipIdToApprovedTranserAddress;
}

 

 
contract TulipsTokenInterface is TulipsStorage, ERC721 {

     

     
    string public constant name = "CryptoTulips";
    string public constant symbol = "CT";

     
    ERC721Metadata public erc721Metadata;

     
    function setMetadataAddress(address _contractAddress) public onlyOperations {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

     

     
    event Transfer(address from, address to, uint256 tokenId);

     
    event Approval(address owner, address approved, uint256 tokenId);

     

     
    mapping (uint256 => address) public tulipIdToApproved;


     
     
    function totalSupply() public view returns (uint) {
        return tulips.length - 1;
    }

     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return tulipOwnershipCount[_owner];
    }

     
    function ownerOf(uint256 _tulipId)
        external
        view
        returns (address owner)
    {
        owner = tulipIdToOwner[_tulipId];

         
        require(owner != address(0));
    }

     
    function approve(
        address _to,
        uint256 _tulipId
    )
        external
        whenNotPaused
    {
         
        require(tulipIdToOwner[_tulipId] == msg.sender);

         
        _approve(_tulipId, _to);

         
        Approval(msg.sender, _to, _tulipId);
    }

     
    function transfer(
        address _to,
        uint256 _tulipId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
        require(_to != address(this));

         
        require(tulipIdToOwner[_tulipId] == msg.sender);

         
        _transfer(msg.sender, _to, _tulipId);
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tulipId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
        require(_to != address(this));

         
        require(tulipIdToApproved[_tulipId] == msg.sender);
        require(tulipIdToOwner[_tulipId] == _from);

         
        _transfer(_from, _to, _tulipId);
    }

     
     
    function tokenMetadata(uint256 _tulipId, string _preferredTransport) external view returns (string infoUrl) {
         
        require(erc721Metadata != address(0));

         
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tulipId, _preferredTransport);

        return _toString(buffer, count);
    }

     
     

    function _transfer(address _from, address _to, uint256 _tulipId) internal {
         
        tulipOwnershipCount[_to]++;

         
        if (_from != address(0)) {
            tulipOwnershipCount[_from]--;
        }

         
        tulipIdToOwner[_tulipId] = _to;

         
        Transfer(_from, _to, _tulipId);
    }

    function _approve(uint256 _tulipId, address _approved) internal{
        tulipIdToApproved[_tulipId] = _approved;
         
    }

     

     
     
     
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength)private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

    function _memcpy(uint dest, uint src, uint len) private view {
         
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

}

 

 
contract TulipsCreation is TulipsTokenInterface {

     
    uint256 public constant TOTAL_TULIP_SUPPLY = 100000;
    uint256 public totalTulipCount;

     
    TulipsSaleInterface public initialSaleContract;

     

     
    event TulipCreation(uint256 tulipId, uint256 visualInfo);

     
    function setSaleAuction(address _initialSaleContractAddress) external onlyOwner {
        initialSaleContract = TulipsSaleInterface(_initialSaleContractAddress);
    }

    function getSaleAuctionAddress() external view returns(address){
        return address(initialSaleContract);
    }

     
     
    function createTulip( uint256 _visualInfo, bytes32 _visualHash )  external onlyOperations
        returns (uint)
    {
        require(totalTulipCount<TOTAL_TULIP_SUPPLY);

        Tulip memory tulip = Tulip({
            visualInfo: _visualInfo,
            visualHash: _visualHash
        });

        uint256 tulipId = tulips.push(tulip) - 1;

         
        tulipIdToOwner[tulipId] = address(initialSaleContract);
        initialSaleContract.putOnInitialSale(tulipId);

        totalTulipCount++;

         
        TulipCreation(
            tulipId, _visualInfo
        );

        return tulipId;
    }

     
    function putOnAuction(
        uint256 _tulipId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {

        require(tulipIdToOwner[_tulipId] == msg.sender);

        tulipIdToApproved[_tulipId] = address(initialSaleContract);

        initialSaleContract.createAuction(
            _tulipId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }


}