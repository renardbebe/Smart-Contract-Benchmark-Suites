 

pragma solidity ^0.5.8;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor() public {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
contract WrappedNFT is IERC20, ReentrancyGuard {

     
    using SafeMath for uint256;

     
     
     

     
     
     
    event DepositNFTAndMintToken(
        uint256 nftId
    );

     
     
     
    event BurnTokenAndWithdrawNFT(
        uint256 nftId
    );

     
     
     

     
     
     
     
     
     
     
     
    uint256[] private depositedNftsArray;

     
     
     
     
     
     
     
    mapping (uint256 => bool) public nftIsDepositedInContract;

     
     
     

     
    uint8 constant public decimals = 18;
    string public name = 'Wrapped NFT';
    string public symbol = 'WNFT';

     
     
     
    address public nftCoreAddress;
    NFTCoreContract nftCore;

     
     
     
     
    address public wyvernTokenTransferProxyAddress;
    address public wrappedNFTLiquidationProxyAddress;
    address public uniswapFactoryAddress;

     
     
     

     
     
     
     
     
     
     
    function depositNftsAndMintTokens(uint256[] calldata _nftIds) external nonReentrant {
        require(_nftIds.length > 0, 'you must submit an array with at least one element');
        for(uint i = 0; i < _nftIds.length; i++){
            uint256 nftToDeposit = _nftIds[i];
            require(msg.sender == nftCore.ownerOf(nftToDeposit), 'you do not own this NFT');
            nftCore.transferFrom(msg.sender, address(this), nftToDeposit);
            _pushNft(nftToDeposit);
            emit DepositNFTAndMintToken(nftToDeposit);
        }
        _mint(msg.sender, (_nftIds.length).mul(10**18));
    }

     
     
     
     
     
     
    function burnTokensAndWithdrawNfts(uint256[] calldata _nftIds, address[] calldata _destinationAddresses) external nonReentrant {
        require(_nftIds.length == _destinationAddresses.length, 'you did not provide a destination address for each of the NFTs you wish to withdraw');
        require(_nftIds.length > 0, 'you must submit an array with at least one element');

        uint256 numTokensToBurn = _nftIds.length;
        uint256 numTokensToBurnInWei = numTokensToBurn.mul(10**18);
        require(balanceOf(msg.sender) >= numTokensToBurnInWei, 'you do not own enough ERC20 tokens to withdraw this many NFTs');
        _burn(msg.sender, numTokensToBurnInWei);

        for(uint i = 0; i < numTokensToBurn; i++){
            uint256 nftToWithdraw = _nftIds[i];
            if(nftToWithdraw == 0){
                nftToWithdraw = _popNft();
            } else {
                require(nftIsDepositedInContract[nftToWithdraw] == true, 'this NFT has already been withdrawn');
                require(address(this) == nftCore.ownerOf(nftToWithdraw), 'the contract does not own this NFT');
                nftIsDepositedInContract[nftToWithdraw] = false;
            }
            nftCore.transferFrom(address(this), _destinationAddresses[i], nftToWithdraw);
            emit BurnTokenAndWithdrawNFT(nftToWithdraw);
        }
    }

     
     
    function _pushNft(uint256 _nftId) internal {
        depositedNftsArray.push(_nftId);
        nftIsDepositedInContract[_nftId] = true;
    }

     
     
     
     
     
    function _popNft() internal returns(uint256){
        require(depositedNftsArray.length > 0, 'there are no NFTs in the array');
        uint256 nftId = depositedNftsArray[depositedNftsArray.length - 1];
        depositedNftsArray.length--;
        while(nftIsDepositedInContract[nftId] == false){
            nftId = depositedNftsArray[depositedNftsArray.length - 1];
            depositedNftsArray.length--;
        }
        nftIsDepositedInContract[nftId] = false;
        return nftId;
    }

     
     
     
     
     
     
     
     
     
     
     
    function batchRemoveWithdrawnNFTsFromStorage(uint256 _numSlotsToCheck) external {
        require(_numSlotsToCheck <= depositedNftsArray.length, 'you are trying to batch remove more slots than exist in the array');
        uint256 arrayIndex = depositedNftsArray.length;
        for(uint i = 0; i < _numSlotsToCheck; i++){
            arrayIndex = arrayIndex.sub(1);
            uint256 nftId = depositedNftsArray[arrayIndex];
            if(nftIsDepositedInContract[nftId] == false){
                depositedNftsArray.length--;
            } else {
                return;
            }
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4) {
        require(msg.sender == nftCoreAddress, 'you can only mint tokens if the ERC721 token originates from nftCoreContract');
        _pushNft(_tokenId);
        _mint(_from, 10**18);
        emit DepositNFTAndMintToken(_tokenId);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

     
     
     
     
     
     
     
     
    constructor(address _nftCoreAddress, address _uniswapFactoryAddress, address _wyvernTokenTransferProxyAddress, address _wrappedNFTLiquidationProxyAddress) public {
        nftCore = NFTCoreContract(_nftCoreAddress);
        nftCoreAddress = _nftCoreAddress;

         
         
         
         
        wyvernTokenTransferProxyAddress = _wyvernTokenTransferProxyAddress;
        wrappedNFTLiquidationProxyAddress = _wrappedNFTLiquidationProxyAddress;
        uniswapFactoryAddress = _uniswapFactoryAddress;
    }

     
     
    function() external payable {
        revert("This contract does not accept direct payments");
    }

     
     
     

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    mapping (address => bool) private _haveAddedAllowancesForWhitelistedAddresses;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
     
     
     
     
     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

         
         
         
         
        if(_haveAddedAllowancesForWhitelistedAddresses[to] == false){
            if(uniswapFactoryAddress != address(0)){
                address uniswapExchangeAddress = UniswapFactory(uniswapFactoryAddress).getExchange(address(this));
                if(uniswapExchangeAddress != address(0)){
                    _allowed[to][uniswapExchangeAddress] = ~uint256(0);
                }
            }
            if(wyvernTokenTransferProxyAddress != address(0)){
                _allowed[to][wyvernTokenTransferProxyAddress] = ~uint256(0);
            }
            if(wrappedNFTLiquidationProxyAddress != address(0)){
                _allowed[to][wrappedNFTLiquidationProxyAddress] = ~uint256(0);
            }
            _haveAddedAllowancesForWhitelistedAddresses[to] = true;
        }

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 
contract NFTCoreContract {
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function approve(address _to, uint256 _tokenId) external;
}

 
contract UniswapFactory {
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
 
 
 
 
 
 
contract WrappedNFTFactory is Ownable {

     
     
     

     
     
     
     
     
    event NewWrapperContractCreated(
        address nftContract,
        address wrapperContract
    );

     
     
     

     
    uint256 public wrapperContractsCreated = 0;

     
     
    mapping (address => address) public nftContractToWrapperContract;

     
     
    mapping (address => address) public wrapperContractToNftContract;

     
     
     
     
    mapping (uint256 => address) public idToNftContract;

     
     
     
     
    address public uniswapFactoryAddress;
    address public wyvernTokenTransferProxyAddress;
    address public wrappedNFTLiquidationProxyAddress;

     
     
     

     
     
     
     
    function createWrapperContract(address _nftContractAddress) external {
        require(nftContractToWrapperContract[_nftContractAddress] == address(0), 'a wrapper contract already exists for this nft');
        address wrapperContractAddress = address(new WrappedNFT(_nftContractAddress, uniswapFactoryAddress, wyvernTokenTransferProxyAddress, wrappedNFTLiquidationProxyAddress));
        _addMapping(_nftContractAddress, wrapperContractAddress);
        emit NewWrapperContractCreated(_nftContractAddress, wrapperContractAddress);
    }

     
     
     
     
     
     
     
     
    function importMappingsFromPreviousFactory(uint256 _startIndex, uint256 _endIndex, address _previousFactoryAddress) external onlyOwner {
        for(uint i = _startIndex; i <= _endIndex; i++){
            address nftContractAddress = WrappedNFTFactory(_previousFactoryAddress).idToNftContract(i);
            address wrapperContractAddress = WrappedNFTFactory(_previousFactoryAddress).nftContractToWrapperContract(nftContractAddress);
            require(nftContractToWrapperContract[nftContractAddress] == address(0), 'a wrapper contract already exists for this nft');
            _addMapping(nftContractAddress, wrapperContractAddress);
        }
    }

     
     
     
     
    function updateUniswapFactoryContractAddress(address _newUniswapFactoryAddress) external onlyOwner {
        uniswapFactoryAddress = _newUniswapFactoryAddress;
    }

     
     
     
     
     
    function updateWyvernTokenTransferProxyAddress(address _newWyvernTokenTransferProxyAddress) external onlyOwner {
        wyvernTokenTransferProxyAddress = _newWyvernTokenTransferProxyAddress;
    }

     
     
     
     
     
    function updateWrappedNFTLiquidationProxyAddress(address _newWrappedNFTLiquidationProxyAddress) external onlyOwner {
        wrappedNFTLiquidationProxyAddress = _newWrappedNFTLiquidationProxyAddress;
    }

     
     
     
     
     
     
     
     
     
    function getWrapperContractForNFTContractAddress(address _nftContractAddress) external view returns (address){
        return nftContractToWrapperContract[_nftContractAddress];
    }

    constructor(address _uniswapFactoryAddress, address _wyvernTokenTransferProxyAddress) public {
         
         
         
         
        uniswapFactoryAddress = _uniswapFactoryAddress;  
        wyvernTokenTransferProxyAddress = _wyvernTokenTransferProxyAddress;  
         
         
         
         
        _addMapping(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d, 0x09fE5f0236F0Ea5D930197DCE254d77B04128075);
    }

     
     
     

     
     
     
     
     
    function _addMapping(address _nftContractAddress, address _wrapperContractAddress) internal {
        nftContractToWrapperContract[_nftContractAddress] = _wrapperContractAddress;
        wrapperContractToNftContract[_wrapperContractAddress] = _nftContractAddress;
        idToNftContract[wrapperContractsCreated] = _nftContractAddress;
        wrapperContractsCreated++;
    }
}