 

pragma solidity ^0.5.6;

interface ILinkdropERC20 {

    function verifyLinkdropSignerSignature
    (
        uint _weiAmount,
        address _tokenAddress,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        bytes calldata _signature
    )
    external view returns (bool);

    function verifyReceiverSignature
    (
        address _linkId,
	    address _receiver,
		bytes calldata _signature
    )
    external view returns (bool);

    function checkClaimParams
    (
        uint _weiAmount,
        address _tokenAddress,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        bytes calldata _linkdropSignerSignature,
        address _receiver,
        bytes calldata _receiverSignature,
        uint _fee
    )
    external view returns (bool);

    function claim
    (
        uint _weiAmount,
        address _tokenAddress,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        bytes calldata _linkdropSignerSignature,
        address payable _receiver,
        bytes calldata _receiverSignature,
        address payable _feeReceiver,
        uint _fee
    )
    external returns (bool);

}

interface ILinkdropFactoryERC20 {

    function checkClaimParams
    (
        uint _weiAmount,
        address _tokenAddress,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        address payable _linkdropMaster,
        uint _campaignId,
        bytes calldata _linkdropSignerSignature,
        address _receiver,
        bytes calldata _receiverSignature
    )
    external view
    returns (bool);

    function claim
    (
        uint _weiAmount,
        address _tokenAddress,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        address payable _linkdropMaster,
        uint _campaignId,
        bytes calldata _linkdropSignerSignature,
        address payable _receiver,
        bytes calldata _receiverSignature
    )
    external
    returns (bool);

}

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface ILinkdropERC721 {

    function verifyLinkdropSignerSignatureERC721
    (
        uint _weiAmount,
        address _nftAddress,
        uint _tokenId,
        uint _expiration,
        address _linkId,
        bytes calldata _signature
    )
    external view returns (bool);

    function verifyReceiverSignatureERC721
    (
        address _linkId,
	    address _receiver,
		bytes calldata _signature
    )
    external view returns (bool);

    function checkClaimParamsERC721
    (
        uint _weiAmount,
        address _nftAddress,
        uint _tokenId,
        uint _expiration,
        address _linkId,
        bytes calldata _linkdropSignerSignature,
        address _receiver,
        bytes calldata _receiverSignature,
        uint _fee
    )
    external view returns (bool);

    function claimERC721
    (
        uint _weiAmount,
        address _nftAddress,
        uint _tokenId,
        uint _expiration,
        address _linkId,
        bytes calldata _linkdropSignerSignature,
        address payable _receiver,
        bytes calldata _receiverSignature,
        address payable _feeReceiver,
        uint _fee
    )
    external returns (bool);

}


interface ILinkdropFactoryERC721 {

    function checkClaimParamsERC721
    (
        uint _weiAmount,
        address _nftAddress,
        uint _tokenId,
        uint _expiration,
        address _linkId,
        address payable _linkdropMaster,
        uint _campaignId,
        bytes calldata _linkdropSignerSignature,
        address _receiver,
        bytes calldata _receiverSignature
    )
    external view
    returns (bool);

    function claimERC721
    (
        uint _weiAmount,
        address _nftAddress,
        uint _tokenId,
        uint _expiration,
        address _linkId,
        address payable _linkdropMaster,
        uint _campaignId,
        bytes calldata _linkdropSignerSignature,
        address payable _receiver,
        bytes calldata _receiverSignature
    )
    external
    returns (bool);

}

interface ILinkdropCommon {

    function initialize
    (
        address _owner,
        address payable _linkdropMaster,
        uint _version,
        uint _chainId
    )
    external returns (bool);

    function isClaimedLink(address _linkId) external view returns (bool);
    function isCanceledLink(address _linkId) external view returns (bool);
    function paused() external view returns (bool);
    function cancel(address _linkId) external  returns (bool);
    function withdraw() external returns (bool);
    function pause() external returns (bool);
    function unpause() external returns (bool);
    function addSigner(address _linkdropSigner) external payable returns (bool);
    function removeSigner(address _linkdropSigner) external returns (bool);
    function destroy() external;
    function getMasterCopyVersion() external view returns (uint);
    function () external payable;

}

 
library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
         
        if (signature.length != 65) {
            return (address(0));
        }

         
        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
         
         
         
         
         
         
         
         
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

         
        return ecrecover(hash, v, r, s);
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


 
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


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    function balanceOf(address owner) public view returns (uint256 balance);

     
    function ownerOf(uint256 tokenId) public view returns (address owner);

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


contract LinkdropFactoryStorage is Ownable {

     
    uint public masterCopyVersion;

     
    bytes internal _bytecode;

     
    bytes internal _initcode;

     
    uint public chainId;

     
    mapping (bytes32 => address) public deployed;

     
    event Deployed(address payable indexed owner, uint campaignId, address payable proxy, bytes32 salt);
    event Destroyed(address payable owner, address payable proxy);
    event SetMasterCopy(address masterCopy, uint version);

}

contract FeeManager is Ownable {

    event FeeChanged(address proxy, uint fee);

    mapping (address => uint) fees;

    uint public standardFee = 0.002 ether;

    function setFee(address _proxy, uint _fee) external onlyOwner returns (bool) {
        _setFee(_proxy, _fee);
        return true;
    }

    function _setFee(address _proxy, uint _fee) internal {
        if (fees[_proxy] != 0) {
            require(_fee < fees[_proxy], "CANNOT_INCREASE_FEE");
        }
        fees[_proxy] = _fee;
        emit FeeChanged(_proxy, _fee);
    }

    function setStandardFee(uint _fee) external onlyOwner {
        standardFee = _fee;
    }

}

contract RelayerManager is Ownable {

    mapping (address => bool) public isRelayer;

    event RelayerAdded(address indexed relayer);

    event RelayerRemoved(address indexed relayer);

    function addRelayer(address _relayer) external onlyOwner returns (bool) {
        require(_relayer != address(0) && !isRelayer[_relayer], "INVALID_RELAYER_ADDRESS");
        isRelayer[_relayer] = true;
        emit RelayerAdded(_relayer);
        return true;
    }

    function removeRelayer(address _relayer) external onlyOwner returns (bool) {
        require(isRelayer[_relayer], "INVALID_RELAYER_ADDRESS");
        isRelayer[_relayer] = false;
        emit RelayerRemoved(_relayer);
        return true;
    }

}






contract LinkdropFactoryCommon is LinkdropFactoryStorage, FeeManager, RelayerManager {
    using SafeMath for uint;

     
    function isDeployed(address _linkdropMaster, uint _campaignId) public view returns (bool) {
        return (deployed[salt(_linkdropMaster, _campaignId)] != address(0));
    }

     
    function isClaimedLink(address payable _linkdropMaster, uint _campaignId, address _linkId) public view returns (bool) {

        if (!isDeployed(_linkdropMaster, _campaignId)) {
            return false;
        }
        else {
            address payable proxy = address(uint160(deployed[salt(_linkdropMaster, _campaignId)]));
            return ILinkdropCommon(proxy).isClaimedLink(_linkId);
        }

    }

     
    function deployProxy(uint _campaignId)
    public
    payable
    returns (address payable proxy)
    {
        proxy = _deployProxy(msg.sender, _campaignId);
    }

     
    function deployProxyWithSigner(uint _campaignId, address _signer)
    public
    payable
    returns (address payable proxy)
    {
        proxy = deployProxy(_campaignId);
        ILinkdropCommon(proxy).addSigner(_signer);
    }

     
    function _deployProxy(address payable _linkdropMaster, uint _campaignId)
    internal
    returns (address payable proxy)
    {

        require(!isDeployed(_linkdropMaster, _campaignId), "LINKDROP_PROXY_CONTRACT_ALREADY_DEPLOYED");
        require(_linkdropMaster != address(0), "INVALID_LINKDROP_MASTER_ADDRESS");

        bytes32 salt = salt(_linkdropMaster, _campaignId);
        bytes memory initcode = getInitcode();

        assembly {
            proxy := create2(0, add(initcode, 0x20), mload(initcode), salt)
            if iszero(extcodesize(proxy)) { revert(0, 0) }
        }

        deployed[salt] = proxy;

         
        require
        (
            ILinkdropCommon(proxy).initialize
            (
                address(this),  
                _linkdropMaster,  
                masterCopyVersion,
                chainId
            ),
            "INITIALIZATION_FAILED"
        );

         
        proxy.transfer(msg.value);

         
        _setFee(proxy, standardFee);

        emit Deployed(_linkdropMaster, _campaignId, proxy, salt);
        return proxy;
    }

     
    function destroyProxy(uint _campaignId)
    public
    returns (bool)
    {
        require(isDeployed(msg.sender, _campaignId), "LINKDROP_PROXY_CONTRACT_NOT_DEPLOYED");
        address payable proxy = address(uint160(deployed[salt(msg.sender, _campaignId)]));
        ILinkdropCommon(proxy).destroy();
        delete deployed[salt(msg.sender, _campaignId)];
        delete fees[proxy];
        emit Destroyed(msg.sender, proxy);
        return true;
    }

     
    function getInitcode()
    public view
    returns (bytes memory)
    {
        return _initcode;
    }

     
    function getBytecode()
    public view
    returns (bytes memory)
    {
        return _bytecode;
    }

     
    function setMasterCopy(address payable _masterCopy)
    public onlyOwner
    returns (bool)
    {
        require(_masterCopy != address(0), "INVALID_MASTER_COPY_ADDRESS");
        masterCopyVersion = masterCopyVersion.add(1);

        require
        (
            ILinkdropCommon(_masterCopy).initialize
            (
                address(0),  
                address(0),  
                masterCopyVersion,
                chainId
            ),
            "INITIALIZATION_FAILED"
        );

        bytes memory bytecode = abi.encodePacked
        (
            hex"363d3d373d3d3d363d73",
            _masterCopy,
            hex"5af43d82803e903d91602b57fd5bf3"
        );

        _bytecode = bytecode;

        emit SetMasterCopy(_masterCopy, masterCopyVersion);
        return true;
    }

     
    function getProxyMasterCopyVersion(address _linkdropMaster, uint _campaignId) external view returns (uint) {

        if (!isDeployed(_linkdropMaster, _campaignId)) {
            return masterCopyVersion;
        }
        else {
            address payable proxy = address(uint160(deployed[salt(_linkdropMaster, _campaignId)]));
            return ILinkdropCommon(proxy).getMasterCopyVersion();
        }
    }

     
    function salt(address _linkdropMaster, uint _campaignId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_linkdropMaster, _campaignId));
    }

}




contract LinkdropFactoryERC20 is ILinkdropFactoryERC20, LinkdropFactoryCommon {

     
    function checkClaimParams
    (
        uint _weiAmount,
        address _tokenAddress,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        address payable _linkdropMaster,
        uint _campaignId,
        bytes memory _linkdropSignerSignature,
        address _receiver,
        bytes memory _receiverSignature
    )
    public view
    returns (bool)
    {
         
        require(isDeployed(_linkdropMaster, _campaignId), "LINKDROP_PROXY_CONTRACT_NOT_DEPLOYED");

        uint fee = fees[deployed[salt(_linkdropMaster, _campaignId)]];

        return ILinkdropERC20(deployed[salt(_linkdropMaster, _campaignId)]).checkClaimParams
        (
            _weiAmount,
            _tokenAddress,
            _tokenAmount,
            _expiration,
            _linkId,
            _linkdropSignerSignature,
            _receiver,
            _receiverSignature,
            fee
        );
    }

     
    function claim
    (
        uint _weiAmount,
        address _tokenAddress,
        uint _tokenAmount,
        uint _expiration,
        address _linkId,
        address payable _linkdropMaster,
        uint _campaignId,
        bytes calldata _linkdropSignerSignature,
        address payable _receiver,
        bytes calldata _receiverSignature
    )
    external
    returns (bool)
    {
         
        require(isDeployed(_linkdropMaster, _campaignId), "LINKDROP_PROXY_CONTRACT_NOT_DEPLOYED");

         
        require(isRelayer[msg.sender], "ONLY_RELAYER");

        uint fee = fees[deployed[salt(_linkdropMaster, _campaignId)]];

         
        ILinkdropERC20(deployed[salt(_linkdropMaster, _campaignId)]).claim
        (
            _weiAmount,
            _tokenAddress,
            _tokenAmount,
            _expiration,
            _linkId,
            _linkdropSignerSignature,
            _receiver,
            _receiverSignature,
            msg.sender,  
            fee
        );

        return true;
    }

}




contract LinkdropFactoryERC721 is ILinkdropFactoryERC721, LinkdropFactoryCommon {

     
    function checkClaimParamsERC721
    (
        uint _weiAmount,
        address _nftAddress,
        uint _tokenId,
        uint _expiration,
        address _linkId,
        address payable _linkdropMaster,
        uint _campaignId,
        bytes memory _linkdropSignerSignature,
        address _receiver,
        bytes memory _receiverSignature
    )
    public view
    returns (bool)
    {
         
        require(isDeployed(_linkdropMaster, _campaignId), "LINKDROP_PROXY_CONTRACT_NOT_DEPLOYED");

        uint fee = fees[deployed[salt(_linkdropMaster, _campaignId)]];

        return ILinkdropERC721(deployed[salt(_linkdropMaster, _campaignId)]).checkClaimParamsERC721
        (
            _weiAmount,
            _nftAddress,
            _tokenId,
            _expiration,
            _linkId,
            _linkdropSignerSignature,
            _receiver,
            _receiverSignature,
            fee
        );
    }

     
    function claimERC721
    (
        uint _weiAmount,
        address _nftAddress,
        uint _tokenId,
        uint _expiration,
        address _linkId,
        address payable _linkdropMaster,
        uint _campaignId,
        bytes calldata _linkdropSignerSignature,
        address payable _receiver,
        bytes calldata _receiverSignature
    )
    external
    returns (bool)
    {
         
        require(isDeployed(_linkdropMaster, _campaignId), "LINKDROP_PROXY_CONTRACT_NOT_DEPLOYED");

         
        require(isRelayer[msg.sender], "ONLY_RELAYER");

        uint fee = fees[deployed[salt(_linkdropMaster, _campaignId)]];

         
        ILinkdropERC721(deployed[salt(_linkdropMaster, _campaignId)]).claimERC721
        (
            _weiAmount,
            _nftAddress,
            _tokenId,
            _expiration,
            _linkId,
            _linkdropSignerSignature,
            _receiver,
            _receiverSignature,
            msg.sender,  
            fee
        );

        return true;
    }

}


contract LinkdropFactory is LinkdropFactoryERC20, LinkdropFactoryERC721 {

     
    constructor(address payable _masterCopy, uint _chainId) public {
        _initcode = (hex"6352c7420d6000526103ff60206004601c335afa6040516060f3");
        chainId = _chainId;
        setMasterCopy(_masterCopy);
    }

}