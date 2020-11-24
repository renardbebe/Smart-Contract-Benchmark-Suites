 

pragma solidity ^0.5.3;

 
 
 
 

 
contract FixedAddress {
    address constant ProxyAddress = 0x1234567896326230a28ee368825D11fE6571Be4a;
    address constant TreasuryAddress = 0x12345678979f29eBc99E00bdc5693ddEa564cA80;
    address constant RegistryAddress = 0x12345678982cB986Dd291B50239295E3Cb10Cdf6;

    function getRegistry() internal pure returns (RegistryInterface) {
        return RegistryInterface(RegistryAddress);
    }
}

 
interface RegistryInterface {
    function getOwner() external view returns (address);
    function getExchangeContract() external view returns (address);
    function contractApproved(address traderAddr) external view returns (bool);
    function contractApprovedBoth(address traderAddr1, address traderAddr2) external view returns (bool);
    function acceptNextExchangeContract() external;
}

 
contract AccessModifiers is FixedAddress {

     
    modifier onlyRegistryOwner() {
        require (msg.sender == getRegistry().getOwner(), "onlyRegistryOwner() method called by non-owner.");
        _;
    }

     
     
    modifier onlyApprovedExchange(address trader) {
        require (msg.sender == ProxyAddress, "onlyApprovedExchange() called not by exchange proxy.");
        require (getRegistry().contractApproved(trader), "onlyApprovedExchange() requires approval of the latest contract code by trader.");
        _;
    }

     
    modifier onlyApprovedExchangeBoth(address trader1, address trader2) {
        require (msg.sender == ProxyAddress, "onlyApprovedExchange() called not by exchange proxy.");
        require (getRegistry().contractApprovedBoth(trader1, trader2), "onlyApprovedExchangeBoth() requires approval of the latest contract code by both traders.");
        _;
    }

}

 
interface TreasuryInterface {
    function withdrawEther(address traderAddr, address payable withdrawalAddr, uint amount) external;
    function withdrawERC20Token(uint16 tokenCode, address traderAddr, address withdrawalAddr, uint amount) external;
    function transferTokens(uint16 tokenCode, address fromAddr, address toAddr, uint amount) external;
    function transferTokensTwice(uint16 tokenCode, address fromAddr, address toAddr1, uint amount1, address toAddr2, uint amount2) external;
    function exchangeTokens(uint16 tokenCode1, uint16 tokenCode2, address addr1, address addr2, address addrFee, uint amount1, uint fee1, uint amount2, uint fee2) external;
}

 
 
 
 

 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract Treasury is AccessModifiers, TreasuryInterface {
     

    uint constant EMERGENCY_RELEASE_CHALLENGE_PERIOD = 2 days;

     

     
     
    bool active = false;

     
     
     
    mapping (uint16 => address) public tokenContracts;

     
     
    mapping (uint176 => uint) public tokenAmounts;

     

    event SetActive(bool active);
    event ChangeTokenInfo(uint16 tokenCode, address tokenContract);
    event StartEmergencyRelease(address account);
    event Deposit(uint16 tokenCode, address account, uint amount);
    event Withdrawal(uint16 tokenCode, address traderAddr, address withdrawalAddr, uint amount);
    event EmergencyRelease(uint16 tokenCode, address account, uint amount);

     
     
     
    mapping (address => uint) public emergencyReleaseSince;

     

    constructor () public {
    }

     

    modifier onlyActive() {
        require (active, "Inactive treasury only allows withdrawals.");
        _;
    }

    modifier emergencyReleasePossible(address trader) {
        uint deadline = emergencyReleaseSince[trader];
        require (deadline > 0 && block.timestamp > deadline, "Challenge should be active and deadline expired.");
        _;
    }

     

    function setActive(bool _active) external onlyRegistryOwner() {
        active = _active;

        emit SetActive(active);
    }

    function changeTokenInfo(uint16 tokenCode, address tokenContract) external onlyRegistryOwner() {
        require (tokenCode != 0,
                 "Token code of zero is reserved for Ether.");

        require (tokenContracts[tokenCode] == address(0),
                 "Token contract address can be assigned only once.");

        tokenContracts[tokenCode] = tokenContract;

        emit ChangeTokenInfo(tokenCode, tokenContract);
    }

     

     
    function startEmergencyRelease() external {
        emergencyReleaseSince[msg.sender] = block.timestamp + EMERGENCY_RELEASE_CHALLENGE_PERIOD;

        emit StartEmergencyRelease(msg.sender);
    }

     
    function resetEmergencyRelease(address traderAddr) private {
        if (emergencyReleaseSince[traderAddr] != 0) {
            emergencyReleaseSince[traderAddr] = 0;
        }
    }

     

     

    function depositEther(address account) external payable {
        emit Deposit(0, account, msg.value);

        addBalance(0, account, msg.value);
    }

    function depositERC20Token(uint176 tokenAccount, uint amount) external {
        uint16 tokenCode = uint16(tokenAccount >> 160);
        address tokenContract = tokenContracts[tokenCode];

        require (tokenContract != address(0), "Registered token contract.");

         
        require (safeTransferFrom(tokenContract, msg.sender, address(this), amount),
                 "Could not transfer ERC-20 tokens using transferFrom.");

        address account = address(tokenAccount);
        emit Deposit(tokenCode, account, amount);

        addBalance(tokenCode, account, amount);
    }

     

    function emergencyReleaseEther() external emergencyReleasePossible(msg.sender) {
        uint amount = deductFullBalance(0, msg.sender);

        emit EmergencyRelease(0, msg.sender, amount);

        msg.sender.transfer(amount);
    }

    function emergencyReleaseERC20Token(uint16 tokenCode) external emergencyReleasePossible(msg.sender) {
        uint amount = deductFullBalance(tokenCode, msg.sender);

        emit EmergencyRelease(tokenCode, msg.sender, amount);

        address tokenContract = tokenContracts[tokenCode];
        require (tokenContract != address(0), "Registered token contract.");

        require (safeTransfer(tokenContract, msg.sender, amount),
                 "Could not transfer ERC-20 tokens using transfer.");
    }

     
     
     

    function withdrawEther(address traderAddr, address payable withdrawalAddr, uint amount) external
        onlyActive()
        onlyApprovedExchange(traderAddr) {

        deductBalance(0, traderAddr, amount);
        resetEmergencyRelease(traderAddr);

        emit Withdrawal(0, traderAddr, withdrawalAddr, amount);

        withdrawalAddr.transfer(amount);
    }

    function withdrawERC20Token(uint16 tokenCode, address traderAddr, address withdrawalAddr, uint amount) external
        onlyActive()
        onlyApprovedExchange(traderAddr) {

        deductBalance(tokenCode, traderAddr, amount);
        resetEmergencyRelease(traderAddr);

        address tokenContract = tokenContracts[tokenCode];
        require (tokenContract != address(0), "Registered token contract.");

        require (safeTransfer(tokenContract, withdrawalAddr, amount),
                 "Could not transfer ERC-20 tokens using transfer.");

        emit Withdrawal(tokenCode, traderAddr, withdrawalAddr, amount);
    }

     
     
     
     
     

     
     
    function transferTokens(uint16 tokenCode, address fromAddr, address toAddr, uint amount) external
        onlyActive() onlyApprovedExchange(fromAddr) {

        resetEmergencyRelease(fromAddr);

        deductBalance(tokenCode, fromAddr, amount);
        addBalance(tokenCode, toAddr, amount);
    }

     
    function transferTokensTwice(uint16 tokenCode, address fromAddr, address toAddr1, uint amount1, address toAddr2, uint amount2) external
        onlyActive() onlyApprovedExchange(fromAddr) {

        resetEmergencyRelease(fromAddr);

        deductBalance(tokenCode, fromAddr, amount1 + amount2);

        addBalance(tokenCode, toAddr1, amount1);
        addBalance(tokenCode, toAddr2, amount2);
    }

     
     
     
    function exchangeTokens(
        uint16 tokenCode1, uint16 tokenCode2,
        address addr1, address addr2, address addrFee,
        uint amount1, uint fee1,
        uint amount2, uint fee2) external onlyActive() onlyApprovedExchangeBoth(addr1, addr2) {

        resetEmergencyRelease(addr1);
        resetEmergencyRelease(addr2);

        deductBalance(tokenCode1, addr1, amount1 + fee1);
        deductBalance(tokenCode2, addr2, amount2 + fee2);

        addBalance(tokenCode1, addr2, amount1);
        addBalance(tokenCode2, addr1, amount2);
        addBalance(tokenCode1, addrFee, fee1);
        addBalance(tokenCode2, addrFee, fee2);
    }

     
     

    function deductBalance(uint tokenCode, address addr, uint amount) private {
        uint176 tokenAccount = uint176(tokenCode) << 160 | uint176(addr);
        uint before = tokenAmounts[tokenAccount];
        require (before >= amount, "Enough funds.");
        tokenAmounts[tokenAccount] = before - amount;
    }

    function deductFullBalance(uint tokenCode, address addr) private returns (uint amount) {
        uint176 tokenAccount = uint176(tokenCode) << 160 | uint176(addr);
        amount = tokenAmounts[tokenAccount];
        tokenAmounts[tokenAccount] = 0;
    }

    function addBalance(uint tokenCode, address addr, uint amount) private {
        uint176 tokenAccount = uint176(tokenCode) << 160 | uint176(addr);
        uint before = tokenAmounts[tokenAccount];
        require (before + amount >= before, "No overflow.");
        tokenAmounts[tokenAccount] = before + amount;
    }

     
     
     

    function safeTransfer(address tokenContract, address to, uint value) internal returns (bool success)
    {
         
        (bool call_success, bytes memory return_data) = tokenContract.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        success = false;

        if (call_success) {
            if (return_data.length == 0) {
                 
                success = true;

            } else if (return_data.length == 32) {
                 
                assembly { success := mload(add(return_data, 0x20)) }
            }

        }
    }

    function safeTransferFrom(address tokenContract, address from, address to, uint value) internal returns (bool success)
    {
         
        (bool call_success, bytes memory return_data) = tokenContract.call(abi.encodeWithSelector(0x23b872dd, from, to, value));

        success = false;

        if (call_success) {
            if (return_data.length == 0) {
                success = true;

            } else if (return_data.length == 32) {
                assembly { success := mload(add(return_data, 0x20)) }
            }

        }
    }

}