 

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
pragma solidity ^0.5.0;

interface ILANDRegistry {

   
  function assignNewParcel(int x, int y, address beneficiary) external;
  function assignMultipleParcels(int[] calldata x, int[] calldata y, address beneficiary) external;

   
  function ping() external;

   
  function encodeTokenId(int x, int y) external pure returns (uint256);
  function decodeTokenId(uint value) external pure returns (int, int);
  function exists(int x, int y) external view returns (bool);
  function ownerOfLand(int x, int y) external view returns (address);
  function ownerOfLandMany(int[] calldata x, int[] calldata y) external view returns (address[] memory);
  function landOf(address owner) external view returns (int[] memory, int[] memory);
  function landData(int x, int y) external view returns (string memory);

   
  function transferLand(int x, int y, address to) external;
  function transferManyLand(int[] calldata x, int[] calldata y, address to) external;

   
  function updateLandData(int x, int y, string calldata data) external;
  function updateManyLandData(int[] calldata x, int[] calldata y, string calldata data) external;

   
  function setUpdateOperator(uint256 assetId, address operator) external;

   

  event Update(
    uint256 indexed assetId,
    address indexed holder,
    address indexed operator,
    string data
  );

  event UpdateOperator(
    uint256 indexed assetId,
    address indexed operator
  );

  event DeployAuthorized(
    address indexed _caller,
    address indexed _deployer
  );

  event DeployForbidden(
    address indexed _caller,
    address indexed _deployer
  );
}

 

pragma solidity ^0.5.0;


contract IEstateRegistry {
  function mint(address to, string calldata metadata) external returns (uint256);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);  
  function setManyLandUpdateOperator(uint256 _estateId, uint256[] memory _landIds, address _operator) public;

   
  event CreateEstate(
    address indexed _owner,
    uint256 indexed _estateId,
    string _data
  );

  event AddLand(
    uint256 indexed _estateId,
    uint256 indexed _landId
  );

  event RemoveLand(
    uint256 indexed _estateId,
    uint256 indexed _landId,
    address indexed _destinatary
  );

  event Update(
    uint256 indexed _assetId,
    address indexed _holder,
    address indexed _operator,
    string _data
  );

  event UpdateOperator(
    uint256 indexed _estateId,
    address indexed _operator
  );

  event UpdateManager(
    address indexed _owner,
    address indexed _operator,
    address indexed _caller,
    bool _approved
  );

  event SetLANDRegistry(
    address indexed _registry
  );
}

 

pragma solidity ^0.5.0;




contract AetheriaFirstStageProxy is Ownable {
    ILANDRegistry private landContract;
	IEstateRegistry private estateContract;
	uint256 private estateId;
	address private delegatedSigner;
	mapping(uint256 => uint) private replayProtection;
	uint public currentNonce;

	constructor (address landContractAddress, address estateContractAddress, uint256 _estateId) public {
        landContract = ILANDRegistry(landContractAddress);
		estateContract = IEstateRegistry(estateContractAddress);
		estateId = _estateId;
		delegatedSigner = owner();
		currentNonce = 1;
    }

	function _isReplayProtectionValid(uint256[] memory plotIds, uint nonce) private view returns (bool) {
		for(uint i = 0; i < plotIds.length; i++) {
			if(replayProtection[plotIds[i]] > nonce) {
				return false;
			}
		}
		return true;
	}

	function setDelegatedSigner(address newDelegate) external onlyOwner {
		delegatedSigner = newDelegate;
		emit DelegateChanged(delegatedSigner);
	}

	function getDelegatedSigner() public view returns (address ){
		return delegatedSigner;
	}

	function getMessageHash(address userAddress, uint256[] memory plotIds, uint nonce) public pure returns (bytes32)
	{
		return keccak256(abi.encode(userAddress, plotIds, nonce));
	}

	function buildPrefixedHash(bytes32 msgHash) public pure returns (bytes32)
	{
		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		return keccak256(abi.encodePacked(prefix, msgHash));
	}

	function verifySender(bytes32 msgHash, uint8 _v, bytes32 _r, bytes32 _s) private view returns (bool)
	{
		bytes32 prefixedHash = buildPrefixedHash(msgHash);
		return ecrecover(prefixedHash, _v, _r, _s) == delegatedSigner;
	}

	function updatePlot(address userAddress, uint256[] calldata plotIds, uint nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
		bytes32 msgHash = getMessageHash(userAddress, plotIds, nonce);
		require(verifySender(msgHash, _v, _r, _s), "Invalid Sig");
		require(_isReplayProtectionValid(plotIds, nonce), "Nonce to low");
        for (uint i = 0; i<plotIds.length; i++) {
			replayProtection[plotIds[i]] = nonce;
        }
		estateContract.setManyLandUpdateOperator(estateId, plotIds, userAddress);
        if (currentNonce <= nonce)
        {
            currentNonce = nonce+1;
        }
		emit PlotOwnerUpdate(
			userAddress,
			plotIds
		);
	}

	event DelegateChanged(
		address newDelegatedAddress
	);

	event PlotOwnerUpdate(
		address newOperator,
		uint256[] plotIds
	);
}