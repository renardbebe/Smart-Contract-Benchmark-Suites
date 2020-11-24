 

 

pragma solidity ^0.5.2;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.2;


contract SignerRole {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () internal {
        _addSigner(msg.sender);
    }

    modifier onlySigner() {
        require(isSigner(msg.sender));
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(msg.sender);
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;

 
contract Secondary {
    address private _primary;

    event PrimaryTransferred(
        address recipient
    );

     
    constructor () internal {
        _primary = msg.sender;
        emit PrimaryTransferred(_primary);
    }

     
    modifier onlyPrimary() {
        require(msg.sender == _primary);
        _;
    }

     
    function primary() public view returns (address) {
        return _primary;
    }

     
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0));
        _primary = recipient;
        emit PrimaryTransferred(_primary);
    }
}

 

pragma solidity ^0.5.2;



 
contract CharityVault is Secondary {
    using SafeMath for uint256;

    mapping(address => uint256) private deposits;
    uint256 public sumStats;

    event LogEthReceived(
        uint256 amount,
        address indexed account
    );
    event LogEthSent(
        uint256 amount,
        address indexed account
    );

     
    function() external payable {
        sumStats.add(msg.value);
        emit LogEthReceived(msg.value, msg.sender);
    }

     
    function deposit(address _payee) public onlyPrimary payable {
        uint256 _amount = msg.value;
        deposits[_payee] = deposits[_payee].add(_amount);
        sumStats = sumStats.add(_amount);
        emit LogEthReceived(_amount, _payee);
    }

     
    function withdraw(address payable _payee, uint256 _payment) public onlyPrimary {
        require(_payment > 0 && address(this).balance >= _payment, "Insufficient funds in the charity fund");
        _payee.transfer(_payment);
        emit LogEthSent(_payment, _payee);
    }

    function depositsOf(address payee) public view returns (uint256) {
        return deposits[payee];
    }
}

 

pragma solidity ^0.5.2;




 
contract DonationCommunity is SignerRole {
    using SafeMath for uint256;

    uint256 public constant CHARITY_DISTRIBUTION = 90;  

    CharityVault public charityVault;
    BondingVaultInterface public bondingVault;

    event LogDonationReceived
    (
        address from,
        uint256 amount
    );
    event LogTokensSold
    (
        address from,
        uint256 amount
    );
    event LogPassToCharity
    (
        address by,
        address intermediary,
        uint256 amount,
        string ipfsHash
    );

     
    function() external payable {
        address(charityVault).transfer(msg.value);
    }

     
    constructor (address payable _charityVaultAddress, address payable _bondingVaultAddress) public {
        require(_bondingVaultAddress != address(0));
        if (_charityVaultAddress == address(0)) {
            charityVault = new CharityVault();
        } else {
            charityVault = CharityVault(_charityVaultAddress);
        }
        bondingVault = BondingVaultInterface(_bondingVaultAddress);
    }

    function donate() public payable {
        donateDelegated(msg.sender);
    }

     
    function donateDelegated(address payable _donator) public payable {
        require(msg.value > 0, "Must include some ETH to donate");

        uint256 _multiplier = 100;
        uint256 _charityAllocation = (msg.value).mul(CHARITY_DISTRIBUTION).div(_multiplier);
        uint256 _bondingAllocation = msg.value.sub(_charityAllocation);
        charityVault.deposit.value(_charityAllocation)(_donator);

        bondingVault.fundWithAward.value(_bondingAllocation)(_donator);

        emit LogDonationReceived(_donator, msg.value);
    }

    function myBuy(uint256 _ethAmount) public view returns (uint256 finalPrice, uint256 tokenAmount) {
        return bondingVault.myBuyPrice(_ethAmount, msg.sender);
    }

    function myReturn(uint256 _sellAmount) public view returns (uint256 price, uint256 amountOfEth) {
        return returnForAddress(_sellAmount, msg.sender);
    }

    function returnForAddress(uint256 _sellAmount, address payable _requestedAddress) public view returns (uint256 price, uint256 amountOfEth) {
        return bondingVault.mySellPrice(_sellAmount, _requestedAddress);
    }

    function sell(uint256 _amount) public {
        bondingVault.sell(_amount, msg.sender);
        emit LogTokensSold(msg.sender, _amount);
    }

    function sweepBondingVault() public onlySigner {
        bondingVault.sweepVault(msg.sender);
    }

    function passToCharity(uint256 _amount, address payable _intermediary, string memory _ipfsHash) public onlySigner {
        require(_intermediary != address(0));
        charityVault.withdraw(_intermediary, _amount);
        emit LogPassToCharity(msg.sender, _intermediary, _amount, _ipfsHash);
    }

    function getCommunityToken() public view returns (address) {
        return bondingVault.getCommunityToken();
    }

     

    function replaceBuyFormula(address _newBuyFormula) public onlySigner {
        bondingVault.setBuyFormula(_newBuyFormula);
    }

    function replaceSellFormula(address _newSellFormula) public onlySigner {
        bondingVault.setSellFormula(_newSellFormula);
    }

    function replaceBondingVault(address _newBondingVault) public onlySigner {
        bondingVault = BondingVaultInterface(_newBondingVault);
    }

    function replaceCharityVault() public onlySigner {
        charityVault = new CharityVault();
    }

     
    function transferOwnership(address newPrimary) public onlySigner {
        charityVault.transferPrimary(newPrimary);
        bondingVault.transferPrimary(newPrimary);
    }


}

interface BondingVaultInterface {

    function fundWithAward(address payable _donator) external payable;

    function sell(uint256 _amount, address payable _donator) external;

    function getCommunityToken() external view returns (address);

    function myBuyPrice(uint256 _ethAmount, address payable _donator) external view returns (uint256 _finalPrice, uint256 _tokenAmount);

    function mySellPrice(uint256 _tokenAmount, address payable _donator) external view returns (uint256 _finalPrice, uint256 _redeemableEth);

    function sweepVault(address payable _operator) external;

    function setBuyFormula(address _newBuyFormula) external;

    function setSellFormula(address _newSellFormula) external;

    function transferPrimary(address recipient) external;

}