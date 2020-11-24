 
contract EBitcoin is IERC20, ERC20, ERC20Detailed, ERC20Pow, Ownable {

    using SafeMath for uint256;

    struct BankAccount {
        uint256 balance;
        uint256 interestSettled;
        uint256 lastBlockNumber;
    }

    mapping (address => BankAccount) private _bankAccounts;

     
    uint256 private _interestInterval = 144;

     
    constructor ()
        ERC20Detailed("EBitcoin Token", "EBT", 8)
        ERC20Pow(2**16, 2**232, 210000, 5000000000, 504, 60, 144)
    public {}

     
    function bankBalanceOf(address account) public view returns (uint256) {
        return _bankAccounts[account].balance;
    }

     
    function bankInterestOf(address account) public view returns (uint256) {

         
        BankAccount storage item = _bankAccounts[account];
        if(0 == item.balance)  return 0;

         
        uint256 blockNumber = getBlockCount();
        uint256 intervalCount = blockNumber.sub(item.lastBlockNumber).div(_interestInterval);
        uint256 interest = item.balance.mul(intervalCount).div(365).div(100);
        return interest.add(item.interestSettled);
    }

     
    function bankDeposit(uint256 amount) public returns (bool) {

         
        uint256 balance = _getBalance(msg.sender);
        _setBalance(msg.sender, balance.sub(amount, "Token: bank deposit amount exceeds balance"));

         
        BankAccount storage item = _bankAccounts[msg.sender];
        if (0 != item.balance) {

             
            uint256 blockNumber = getBlockCount();
            uint256 intervalCount = blockNumber.sub(item.lastBlockNumber).div(_interestInterval);
            uint256 interest = item.balance.mul(intervalCount).div(365).div(100);

             
            item.balance = item.balance.add(amount);
            item.interestSettled = item.interestSettled.add(interest);
            item.lastBlockNumber = blockNumber;
        }
        else {

             
            item.balance = amount;
            item.interestSettled = 0;
            item.lastBlockNumber = getBlockCount();
        }

        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

     
    function bankWithdrawal(uint256 amount) public returns (bool) {

         
        BankAccount storage item = _bankAccounts[msg.sender];
        require(0 == amount || 0 != item.balance, "Token: withdrawal amount exceeds bank balance");

         
        uint256 blockNumber = getBlockCount();
        uint256 intervalCount = blockNumber.sub(item.lastBlockNumber).div(_interestInterval);
        uint256 interest = item.balance.mul(intervalCount).div(365).div(100);
        interest = interest.add(item.interestSettled);

         
        if (interest >= amount) {

             
            item.lastBlockNumber = blockNumber;
            item.interestSettled = interest.sub(amount);

             
            _setBalance(msg.sender, _getBalance(msg.sender).add(amount));
            _setTotalSupply(_getTotalSupply().add(amount));
        }
        else {

             
            uint256 remainAmount = amount.sub(interest);
            item.balance = item.balance.sub(remainAmount, "Token: withdrawal amount exceeds bank balance");
            item.lastBlockNumber = blockNumber;
            item.interestSettled = 0;

             
            _setBalance(msg.sender, _getBalance(msg.sender).add(amount));
            _setTotalSupply(_getTotalSupply().add(interest));
        }

        emit Transfer(address(0), msg.sender, amount);
        return true;
    }

     
    function transferAnyERC20Token(address tokenAddress, uint256 amount) public onlyOwner returns (bool) {
        return IERC20(tokenAddress).transfer(getOwner(), amount);
    }
}