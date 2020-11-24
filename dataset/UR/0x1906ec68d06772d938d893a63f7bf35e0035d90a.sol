 

pragma solidity >=0.4.22 <0.6.0;

 
 
 
 
 
 
contract Ownable {
     
     
     
    event OwnershipTransfer (address previousOwner, address newOwner);
    
     
    address owner;
    
     
     
     
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransfer(address(0), owner);
    }

     
     
     
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Function can only be called by contract owner"
        );
        _;
    }

     
     
     
     
     
    function transferOwnership(address _newOwner) public onlyOwner {
         
        require (
            _newOwner != address(0),
            "New owner address cannot be zero"
        );
         
        address oldOwner = owner;
         
        owner = _newOwner;
         
        emit OwnershipTransfer(oldOwner, _newOwner);
    }
}


 
 
 
interface VIP181 {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(
        address _owner, 
        address _operator
    ) external view returns (bool);
}

interface VIP180 {
    function transferFrom(address _from, address _to, uint _tokens) external returns (bool);
}

interface LockedTokenManager {    
    function lockFrom(
        address _tokenHolder, 
        address _tokenAddress, 
        uint _tokens, 
        uint _numberOfMonths
    ) external returns(bool);
    
    function transferFromAndLock(
        address _from,
        address _to,
        address _tokenAddress,
        uint _tokens,
        uint _numberOfMonths
    ) external returns (bool);
}


contract SegmentedTransfer is Ownable {
    
    struct TransferSettings {
        uint burnedPercent;
        uint lockedPercent;
        uint transferredThenLockedPercent;
        uint lockedMonths;
    }
     
    LockedTokenManager public lockContract;

     
     
     
    modifier notZero(uint _param) {
        require(_param != 0, "Parameter cannot be zero");
        _;
    }
    
     
     
     
     
     
    function setLockContract (address _lockAddress)
        external 
        notZero(uint(_lockAddress)) 
        onlyOwner
    {
         
        lockContract = LockedTokenManager(_lockAddress);
    }
    
     
     
     
    function segmentedTransfer(
        address _tokenContractAddress,
        address _to,
        uint _totalTokens,
        TransferSettings storage _transfer
    ) internal {
        uint tokensLeft = _totalTokens;
        uint amount;
         
        if (_transfer.burnedPercent > 0) {
            amount = _totalTokens * _transfer.burnedPercent / 100;
            VIP180(_tokenContractAddress).transferFrom(msg.sender, address(0), amount);
            tokensLeft -= amount;
        }
         
        if (_transfer.lockedPercent > 0) {
            amount = _totalTokens * _transfer.lockedPercent / 100;
            lockContract.lockFrom(
                msg.sender, 
                _tokenContractAddress, 
                _transfer.lockedMonths, 
                amount
            );
            tokensLeft -= amount;
        }
         
        if (_transfer.transferredThenLockedPercent > 0) {
            amount = _totalTokens * _transfer.transferredThenLockedPercent / 100;
            lockContract.transferFromAndLock(
                msg.sender, 
                address(_to), 
                _tokenContractAddress, 
                _transfer.lockedMonths, 
                amount
            );
            tokensLeft -= amount;
        }
         
        if (tokensLeft > 0) {
            VIP180(_tokenContractAddress).transferFrom(msg.sender, _to, tokensLeft);
        }
    }   
}


 
 
 
 
 
contract AacColoredTokens is SegmentedTransfer {
     
     
     
    event NewColor(address indexed _creator, string _name);

     
     
     
    event DepositColor(uint indexed _to, uint indexed _colorIndex, uint _tokens);

     
     
     
    event SpendColor(
        uint indexed _from, 
        uint indexed _color, 
        uint _amount
    );

     
    struct ColoredToken {
        address creator;
        string name;
        mapping (uint => uint) balances;
        mapping (address => uint) depositAllowances;
    }

     
    ColoredToken[] coloredTokens;
     
    uint public priceToRegisterColor = 100000 * 10**18;
     
    VIP181 public aacContract;
     
    address public ehrtAddress;
     
    TransferSettings public colorRegistrationTransfer = TransferSettings({
        burnedPercent: 50,
        lockedPercent: 0,
        transferredThenLockedPercent: 0,
        lockedMonths: 24
    });
     
    TransferSettings public colorDepositTransfer = TransferSettings({
        burnedPercent: 50,
        lockedPercent: 0,
        transferredThenLockedPercent: 0,
        lockedMonths: 24
    });
    uint constant UID_MAX = 0xFFFFFFFFFFFFFF;

     
     
     
     
     
    function setAacContract (address _aacAddress) 
        external 
        notZero(uint(_aacAddress)) 
        onlyOwner
    {
         
        aacContract = VIP181(_aacAddress);
    }
    
     
     
     
     
     
    function setEhrtContractAddress (address _newAddress) 
        external 
        notZero(uint(_newAddress)) 
        onlyOwner
    {
         
        ehrtAddress = _newAddress;
    }

     
     
     
     
     
     
     
    function setPriceToRegisterColor(uint _newAmount) 
        external 
        onlyOwner
        notZero(_newAmount)
    {
        priceToRegisterColor = _newAmount;
    }
    
    function setTransferSettingsForColoredTokenCreation(
        uint _burnPercent,
        uint _lockPercent,
        uint _transferLockPercent,
        uint _lockedMonths
    ) external onlyOwner {
        require(_burnPercent + _lockPercent + _transferLockPercent <= 100);
        colorRegistrationTransfer = TransferSettings(
            _burnPercent, 
            _lockPercent, 
            _transferLockPercent,
            _lockedMonths
        );
    }
    
    function setTransferSettingsForColoredTokenDeposits(
        uint _burnPercent,
        uint _lockPercent,
        uint _transferLockPercent,
        uint _lockedMonths
    ) external onlyOwner {
        require(_burnPercent + _lockPercent + _transferLockPercent <= 100);
        colorDepositTransfer = TransferSettings(
            _burnPercent, 
            _lockPercent, 
            _transferLockPercent,
            _lockedMonths
        );
    }
    
     
     
     
     
     
     
     
     
    function registerNewColor(string calldata _colorName) external returns (uint) {
         
        require (
            bytes(_colorName).length > 0 && bytes(_colorName).length < 32,
            "Invalid color name length"
        );
         
        segmentedTransfer(ehrtAddress, owner, priceToRegisterColor, colorRegistrationTransfer);
         
        uint index = coloredTokens.push(ColoredToken(msg.sender, _colorName));
        return index;
    }
    
     
     
     
     
     
     
     
     
    function approve(uint _colorIndex, address _spender, uint _tokens) external {
        require(msg.sender == coloredTokens[_colorIndex].creator);
         
        coloredTokens[_colorIndex].depositAllowances[_spender] = _tokens;
    }

     
     
     
     
     
     
     
     
     
     
     
    function deposit (uint _colorIndex, uint _to, uint _tokens)
        external 
        notZero(_tokens)
    {
         
        require (_colorIndex < coloredTokens.length, "Invalid color index");
         
        require (
            msg.sender == coloredTokens[_colorIndex].creator ||
            coloredTokens[_colorIndex].depositAllowances[msg.sender] >= _tokens,
            "Not authorized to deposit this color"
        );
         
        require(aacContract.ownerOf(_to) != address(0), "AAC does not exist");
        
         
        segmentedTransfer(ehrtAddress, owner, _tokens, colorDepositTransfer);

         
        coloredTokens[_colorIndex].balances[_to] += _tokens;
        
         
        if (msg.sender != coloredTokens[_colorIndex].creator) {
            coloredTokens[_colorIndex].depositAllowances[msg.sender] -= _tokens;
        }
        
         
        emit DepositColor(_to, _colorIndex, _tokens);
    }

     
     
     
     
     
     
     
     
     
     
     
    function depositBulk (uint _colorIndex, uint[] calldata _to, uint _tokens)
        external 
        notZero(_tokens)
    {
         
        require (_colorIndex < coloredTokens.length, "Invalid color index");
         
        require (
            msg.sender == coloredTokens[_colorIndex].creator ||
            coloredTokens[_colorIndex].depositAllowances[msg.sender] > _tokens * _to.length,
            "Not authorized to deposit this color"
        );

         
        segmentedTransfer(ehrtAddress, owner, _tokens * _to.length, colorDepositTransfer);

        for(uint i = 0; i < _to.length; ++i){
             
            require(aacContract.ownerOf(_to[i]) != address(0), "AAC does not exist");

             
            coloredTokens[_colorIndex].balances[_to[i]] += _tokens;
             
            emit DepositColor(_to[i], _colorIndex, _tokens);
        }
        
         
        if (msg.sender != coloredTokens[_colorIndex].creator) {
            coloredTokens[_colorIndex].depositAllowances[msg.sender] -= _tokens * _to.length;
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function spend (uint _colorIndex, uint _from, uint _tokens) 
        external 
        notZero(_tokens)
        returns(bool) 
    {
         
        require (_colorIndex < coloredTokens.length, "Invalid color index");
         
        require (
            msg.sender == aacContract.ownerOf(_from), 
            "Sender is not owner of AAC"
        );
         
        require (
            coloredTokens[_colorIndex].balances[_from] >= _tokens,
            "Insufficient tokens to spend"
        );
         
        coloredTokens[_colorIndex].balances[_from] -= _tokens;
         
        emit SpendColor(_from, _colorIndex, _tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function spendFrom(uint _colorIndex, uint _from, uint _tokens)
        external 
        notZero(_tokens)
        returns (bool) 
    {
         
        require (_colorIndex < coloredTokens.length, "Invalid color index");
         
        require (
            msg.sender == aacContract.getApproved(_from) ||
            aacContract.isApprovedForAll(aacContract.ownerOf(_from), msg.sender), 
            "Sender is not authorized operator for AAC"
        );
         
        require (
            coloredTokens[_colorIndex].balances[_from] >= _tokens,
            "Insufficient balance to spend"
        );
         
        coloredTokens[_colorIndex].balances[_from] -= _tokens;
         
        emit SpendColor(_from, _colorIndex, _tokens);
        return true;
    }

     
     
     
     
     
    function onLink(uint _oldUid, uint _newUid) external {
        require (msg.sender == address(aacContract), "Unauthorized transaction");
        require (_oldUid > UID_MAX && _newUid <= UID_MAX);
        for(uint i = 0; i < coloredTokens.length; ++i) {
            coloredTokens[i].balances[_newUid] = coloredTokens[i].balances[_oldUid];
        }
    }
    
     
     
     
     
     
     
     
     
    function getColoredTokenBalance(uint _uid, uint _colorIndex) 
        external 
        view 
        returns(uint) 
    {
        return coloredTokens[_colorIndex].balances[_uid];
    }

     
     
     
     
    function coloredTokenCount() external view returns (uint) {
        return coloredTokens.length;
    }

     
     
     
     
     
     
    function getColoredToken(uint _colorIndex) 
        external 
        view 
        returns(address, string memory)
    {
        return (
            coloredTokens[_colorIndex].creator, 
            coloredTokens[_colorIndex].name
        );
    }
}