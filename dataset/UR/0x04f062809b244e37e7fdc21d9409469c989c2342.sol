 

pragma solidity 0.4.19;

 
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
contract Migratable {
    function migrate(address user, uint256 amount, address tokenAddr) external payable returns (bool);
}

 
contract JoysoDataDecoder {
    function decodeOrderUserId(uint256 data) internal pure returns (uint256) {
        return data & 0x00000000000000000000000000000000000000000000000000000000ffffffff;
    }

    function retrieveV(uint256 data) internal pure returns (uint256) {
         
        return data & 0x000000000000000000000000f000000000000000000000000000000000000000 == 0 ? 27 : 28;
    }
}


 
contract Joyso is Ownable, JoysoDataDecoder {
    using SafeMath for uint256;

    uint256 private constant USER_MASK = 0x00000000000000000000000000000000000000000000000000000000ffffffff;
    uint256 private constant PAYMENT_METHOD_MASK = 0x00000000000000000000000f0000000000000000000000000000000000000000;
    uint256 private constant WITHDRAW_TOKEN_MASK = 0x0000000000000000000000000000000000000000000000000000ffff00000000;
    uint256 private constant V_MASK = 0x000000000000000000000000f000000000000000000000000000000000000000;
    uint256 private constant TOKEN_SELL_MASK = 0x000000000000000000000000000000000000000000000000ffff000000000000;
    uint256 private constant TOKEN_BUY_MASK = 0x0000000000000000000000000000000000000000000000000000ffff00000000;
    uint256 private constant SIGN_MASK = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
    uint256 private constant MATCH_SIGN_MASK = 0xfffffffffffffffffffffff00000000000000000000000000000000000000000;
    uint256 private constant TOKEN_JOY_PRICE_MASK = 0x0000000000000000000000000fffffffffffffffffffffff0000000000000000;
    uint256 private constant JOY_PRICE_MASK = 0x0000000000000000fffffff00000000000000000000000000000000000000000;
    uint256 private constant IS_BUY_MASK = 0x00000000000000000000000f0000000000000000000000000000000000000000;
    uint256 private constant TAKER_FEE_MASK = 0x00000000ffff0000000000000000000000000000000000000000000000000000;
    uint256 private constant MAKER_FEE_MASK = 0x000000000000ffff000000000000000000000000000000000000000000000000;

    uint256 private constant PAY_BY_TOKEN = 0x0000000000000000000000020000000000000000000000000000000000000000;
    uint256 private constant PAY_BY_JOY = 0x0000000000000000000000010000000000000000000000000000000000000000;
    uint256 private constant ORDER_ISBUY = 0x0000000000000000000000010000000000000000000000000000000000000000;

    mapping (address => mapping (address => uint256)) private balances;
    mapping (address => uint256) public userLock;
    mapping (address => uint256) public userNonce;
    mapping (bytes32 => uint256) public orderFills;
    mapping (bytes32 => bool) public usedHash;
    mapping (address => bool) public isAdmin;
    mapping (uint256 => address) public tokenId2Address;
    mapping (uint256 => address) public userId2Address;
    mapping (address => uint256) public userAddress2Id;
    mapping (address => uint256) public tokenAddress2Id;

    address public joysoWallet;
    address public joyToken;
    uint256 public lockPeriod = 30 days;
    uint256 public userCount;
    bool public tradeEventEnabled = true;

    modifier onlyAdmin {
        require(msg.sender == owner || isAdmin[msg.sender]);
        _;
    }

     
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event NewUser(address user, uint256 id);
    event Lock(address user, uint256 timeLock);

     
    event TradeSuccess(address user, uint256 baseAmount, uint256 tokenAmount, bool isBuy, uint256 fee);

    function Joyso(address _joysoWallet, address _joyToken) public {
        joysoWallet = _joysoWallet;
        addUser(_joysoWallet);
        joyToken = _joyToken;
        tokenAddress2Id[joyToken] = 1;
        tokenAddress2Id[0] = 0;  
        tokenId2Address[0] = 0;
        tokenId2Address[1] = joyToken;
    }

     
    function depositToken(address token, uint256 amount) external {
        require(amount > 0);
        require(tokenAddress2Id[token] != 0);
        addUser(msg.sender);
        require(ERC20(token).transferFrom(msg.sender, this, amount));
        balances[token][msg.sender] = balances[token][msg.sender].add(amount);
        Deposit(
            token,
            msg.sender,
            amount,
            balances[token][msg.sender]
        );
    }

     
    function depositEther() external payable {
        require(msg.value > 0);
        addUser(msg.sender);
        balances[0][msg.sender] = balances[0][msg.sender].add(msg.value);
        Deposit(
            0,
            msg.sender,
            msg.value,
            balances[0][msg.sender]
        );
    }

     
    function withdraw(address token, uint256 amount) external {
        require(amount > 0);
        require(getTime() > userLock[msg.sender] && userLock[msg.sender] != 0);
        balances[token][msg.sender] = balances[token][msg.sender].sub(amount);
        if (token == 0) {
            msg.sender.transfer(amount);
        } else {
            require(ERC20(token).transfer(msg.sender, amount));
        }
        Withdraw(
            token,
            msg.sender,
            amount,
            balances[token][msg.sender]
        );
    }

     
    function lockMe() external {
        require(userAddress2Id[msg.sender] != 0);
        userLock[msg.sender] = getTime() + lockPeriod;
        Lock(msg.sender, userLock[msg.sender]);
    }

     
    function unlockMe() external {
        require(userAddress2Id[msg.sender] != 0);
        userLock[msg.sender] = 0;
        Lock(msg.sender, 0);
    }

     
    function setTradeEventEnabled(bool enabled) external onlyOwner {
        tradeEventEnabled = enabled;
    }

     
    function addToAdmin(address admin, bool isAdd) external onlyOwner {
        isAdmin[admin] = isAdd;
    }

     
    function collectFee(address token) external onlyOwner {
        uint256 amount = balances[token][joysoWallet];
        require(amount > 0);
        balances[token][joysoWallet] = 0;
        if (token == 0) {
            msg.sender.transfer(amount);
        } else {
            require(ERC20(token).transfer(msg.sender, amount));
        }
        Withdraw(
            token,
            joysoWallet,
            amount,
            0
        );
    }

     
    function changeLockPeriod(uint256 periodInDays) external onlyOwner {
        require(periodInDays <= 30 && periodInDays >= 1);
        lockPeriod = periodInDays * 1 days;
    }

     
    function registerToken(address tokenAddress, uint256 index) external onlyAdmin {
        require(index > 1);
        require(tokenAddress2Id[tokenAddress] == 0);
        require(tokenId2Address[index] == 0);
        tokenAddress2Id[tokenAddress] = index;
        tokenId2Address[index] = tokenAddress;
    }

     
    function withdrawByAdmin_Unau(uint256[] inputs) external onlyAdmin {
        uint256 amount = inputs[0];
        uint256 gasFee = inputs[1];
        uint256 data = inputs[2];
        uint256 paymentMethod = data & PAYMENT_METHOD_MASK;
        address token = tokenId2Address[(data & WITHDRAW_TOKEN_MASK) >> 32];
        address user = userId2Address[data & USER_MASK];
        bytes32 hash = keccak256(
            this,
            amount,
            gasFee,
            data & SIGN_MASK | uint256(token)
        );
        require(!usedHash[hash]);
        require(
            verify(
                hash,
                user,
                uint8(data & V_MASK == 0 ? 27 : 28),
                bytes32(inputs[3]),
                bytes32(inputs[4])
            )
        );

        address gasToken = 0;
        if (paymentMethod == PAY_BY_JOY) {  
            gasToken = joyToken;
        } else if (paymentMethod == PAY_BY_TOKEN) {  
            gasToken = token;
        }

        if (gasToken == token) {  
            balances[token][user] = balances[token][user].sub(amount.add(gasFee));
        } else {
            balances[token][user] = balances[token][user].sub(amount);
            balances[gasToken][user] = balances[gasToken][user].sub(gasFee);
        }
        balances[gasToken][joysoWallet] = balances[gasToken][joysoWallet].add(gasFee);

        usedHash[hash] = true;

        if (token == 0) {
            user.transfer(amount);
        } else {
            require(ERC20(token).transfer(user, amount));
        }
    }

     
    function matchByAdmin_TwH36(uint256[] inputs) external onlyAdmin {
        uint256 data = inputs[3];
        address user = userId2Address[data & USER_MASK];
         
        require(data >> 224 > userNonce[user]);
        address token;
        bool isBuy;
        (token, isBuy) = decodeOrderTokenAndIsBuy(data);
        bytes32 orderHash = keccak256(
            this,
            inputs[0],
            inputs[1],
            inputs[2],
            data & MATCH_SIGN_MASK | (isBuy ? ORDER_ISBUY : 0) | uint256(token)
        );
        require(
            verify(
                orderHash,
                user,
                uint8(data & V_MASK == 0 ? 27 : 28),
                bytes32(inputs[4]),
                bytes32(inputs[5])
            )
        );

        uint256 tokenExecute = isBuy ? inputs[1] : inputs[0];  
        tokenExecute = tokenExecute.sub(orderFills[orderHash]);
        require(tokenExecute != 0);  
        uint256 etherExecute = 0;   

        isBuy = !isBuy;
        for (uint256 i = 6; i < inputs.length; i += 6) {
             
            require(tokenExecute > 0 && inputs[1].mul(inputs[i + 1]) <= inputs[0].mul(inputs[i]));

            data = inputs[i + 3];
            user = userId2Address[data & USER_MASK];
             
            require(data >> 224 > userNonce[user]);
            bytes32 makerOrderHash = keccak256(
                this,
                inputs[i],
                inputs[i + 1],
                inputs[i + 2],
                data & MATCH_SIGN_MASK | (isBuy ? ORDER_ISBUY : 0) | uint256(token)
            );
            require(
                verify(
                    makerOrderHash,
                    user,
                    uint8(data & V_MASK == 0 ? 27 : 28),
                    bytes32(inputs[i + 4]),
                    bytes32(inputs[i + 5])
                )
            );
            (tokenExecute, etherExecute) = internalTrade(
                inputs[i],
                inputs[i + 1],
                inputs[i + 2],
                data,
                tokenExecute,
                etherExecute,
                isBuy,
                token,
                0,
                makerOrderHash
            );
        }

        isBuy = !isBuy;
        tokenExecute = isBuy ? inputs[1].sub(tokenExecute) : inputs[0].sub(tokenExecute);
        tokenExecute = tokenExecute.sub(orderFills[orderHash]);
        processTakerOrder(inputs[2], inputs[3], tokenExecute, etherExecute, isBuy, token, 0, orderHash);
    }

     
    function matchTokenOrderByAdmin_k44j(uint256[] inputs) external onlyAdmin {
        address user = userId2Address[decodeOrderUserId(inputs[3])];
         
        require(inputs[3] >> 224 > userNonce[user]);
        address token;
        address base;
        bool isBuy;
        (token, base, isBuy) = decodeTokenOrderTokenAndIsBuy(inputs[3]);
        bytes32 orderHash = getTokenOrderDataHash(inputs, 0, inputs[3], token, base);
        require(
            verify(
                orderHash,
                user,
                uint8(retrieveV(inputs[3])),
                bytes32(inputs[4]),
                bytes32(inputs[5])
            )
        );
        uint256 tokenExecute = isBuy ? inputs[1] : inputs[0];  
        tokenExecute = tokenExecute.sub(orderFills[orderHash]);
        require(tokenExecute != 0);  
        uint256 baseExecute = 0;   

        isBuy = !isBuy;
        for (uint256 i = 6; i < inputs.length; i += 6) {
             
            require(tokenExecute > 0 && inputs[1].mul(inputs[i + 1]) <= inputs[0].mul(inputs[i]));

            user = userId2Address[decodeOrderUserId(inputs[i + 3])];
             
            require(inputs[i + 3] >> 224 > userNonce[user]);
            bytes32 makerOrderHash = getTokenOrderDataHash(inputs, i, inputs[i + 3], token, base);
            require(
                verify(
                    makerOrderHash,
                    user,
                    uint8(retrieveV(inputs[i + 3])),
                    bytes32(inputs[i + 4]),
                    bytes32(inputs[i + 5])
                )
            );
            (tokenExecute, baseExecute) = internalTrade(
                inputs[i],
                inputs[i + 1],
                inputs[i + 2],
                inputs[i + 3],
                tokenExecute,
                baseExecute,
                isBuy,
                token,
                base,
                makerOrderHash
            );
        }

        isBuy = !isBuy;
        tokenExecute = isBuy ? inputs[1].sub(tokenExecute) : inputs[0].sub(tokenExecute);
        tokenExecute = tokenExecute.sub(orderFills[orderHash]);
        processTakerOrder(inputs[2], inputs[3], tokenExecute, baseExecute, isBuy, token, base, orderHash);
    }

     
    function cancelByAdmin(uint256[] inputs) external onlyAdmin {
        uint256 data = inputs[1];
        uint256 nonce = data >> 224;
        address user = userId2Address[data & USER_MASK];
        require(nonce > userNonce[user]);
        uint256 gasFee = inputs[0];
        require(
            verify(
                keccak256(this, gasFee, data & SIGN_MASK),
                user,
                uint8(retrieveV(data)),
                bytes32(inputs[2]),
                bytes32(inputs[3])
            )
        );

         
        address gasToken = 0;
        if (data & PAYMENT_METHOD_MASK == PAY_BY_JOY) {
            gasToken = joyToken;
        }
        require(balances[gasToken][user] >= gasFee);
        balances[gasToken][user] = balances[gasToken][user].sub(gasFee);
        balances[gasToken][joysoWallet] = balances[gasToken][joysoWallet].add(gasFee);

         
        userNonce[user] = nonce;
    }

     
    function migrateByAdmin_DQV(uint256[] inputs) external onlyAdmin {
        uint256 data = inputs[2];
        address token = tokenId2Address[(data & WITHDRAW_TOKEN_MASK) >> 32];
        address newContract = address(inputs[0]);
        for (uint256 i = 1; i < inputs.length; i += 4) {
            uint256 gasFee = inputs[i];
            data = inputs[i + 1];
            address user = userId2Address[data & USER_MASK];
            bytes32 hash = keccak256(
                this,
                gasFee,
                data & SIGN_MASK | uint256(token),
                newContract
            );
            require(
                verify(
                    hash,
                    user,
                    uint8(data & V_MASK == 0 ? 27 : 28),
                    bytes32(inputs[i + 2]),
                    bytes32(inputs[i + 3])
                )
            );
            if (gasFee > 0) {
                uint256 paymentMethod = data & PAYMENT_METHOD_MASK;
                if (paymentMethod == PAY_BY_JOY) {
                    balances[joyToken][user] = balances[joyToken][user].sub(gasFee);
                    balances[joyToken][joysoWallet] = balances[joyToken][joysoWallet].add(gasFee);
                } else if (paymentMethod == PAY_BY_TOKEN) {
                    balances[token][user] = balances[token][user].sub(gasFee);
                    balances[token][joysoWallet] = balances[token][joysoWallet].add(gasFee);
                } else {
                    balances[0][user] = balances[0][user].sub(gasFee);
                    balances[0][joysoWallet] = balances[0][joysoWallet].add(gasFee);
                }
            }
            uint256 amount = balances[token][user];
            balances[token][user] = 0;
            if (token == 0) {
                Migratable(newContract).migrate.value(amount)(user, amount, token);
            } else {
                ERC20(token).approve(newContract, amount);
                Migratable(newContract).migrate(user, amount, token);
            }
        }
    }

     
    function transferForAdmin(address token, address account, uint256 amount) onlyAdmin external {
        require(tokenAddress2Id[token] != 0);
        require(userAddress2Id[msg.sender] != 0);
        addUser(account);
        balances[token][msg.sender] = balances[token][msg.sender].sub(amount);
        balances[token][account] = balances[token][account].add(amount);
    }

     
    function getBalance(address token, address account) external view returns (uint256) {
        return balances[token][account];
    }

     
    function decodeOrderTokenAndIsBuy(uint256 data) internal view returns (address token, bool isBuy) {
        uint256 tokenId = (data & TOKEN_SELL_MASK) >> 48;
        if (tokenId == 0) {
            token = tokenId2Address[(data & TOKEN_BUY_MASK) >> 32];
            isBuy = true;
        } else {
            token = tokenId2Address[tokenId];
        }
    }

     
    function decodeTokenOrderTokenAndIsBuy(uint256 data) internal view returns (address token, address base, bool isBuy) {
        isBuy = data & IS_BUY_MASK == ORDER_ISBUY;
        if (isBuy) {
            token = tokenId2Address[(data & TOKEN_BUY_MASK) >> 32];
            base = tokenId2Address[(data & TOKEN_SELL_MASK) >> 48];
        } else {
            token = tokenId2Address[(data & TOKEN_SELL_MASK) >> 48];
            base = tokenId2Address[(data & TOKEN_BUY_MASK) >> 32];
        }
    }

    function getTime() internal view returns (uint256) {
        return now;
    }

     
    function getTokenOrderDataHash(uint256[] inputs, uint256 offset, uint256 data, address token, address base) internal view returns (bytes32) {
        return keccak256(
            this,
            inputs[offset],
            inputs[offset + 1],
            inputs[offset + 2],
            data & SIGN_MASK | uint256(token),
            base,
            (data & TOKEN_JOY_PRICE_MASK) >> 64
        );
    }

     
    function verify(bytes32 hash, address sender, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        return ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == sender;
    }

     
    function addUser(address _address) internal {
        if (userAddress2Id[_address] != 0) {
            return;
        }
        userCount += 1;
        userAddress2Id[_address] = userCount;
        userId2Address[userCount] = _address;
        NewUser(_address, userCount);
    }

    function processTakerOrder(
        uint256 gasFee,
        uint256 data,
        uint256 tokenExecute,
        uint256 baseExecute,
        bool isBuy,
        address token,
        address base,
        bytes32 orderHash
    )
        internal
    {
        uint256 fee = calculateFee(gasFee, data, baseExecute, orderHash, true, base == 0);
        updateUserBalance(data, isBuy, baseExecute, tokenExecute, fee, token, base);
        orderFills[orderHash] = orderFills[orderHash].add(tokenExecute);
        if (tradeEventEnabled) {
            TradeSuccess(userId2Address[data & USER_MASK], baseExecute, tokenExecute, isBuy, fee);
        }
    }

    function internalTrade(
        uint256 amountSell,
        uint256 amountBuy,
        uint256 gasFee,
        uint256 data,
        uint256 _remainingToken,
        uint256 _baseExecute,
        bool isBuy,
        address token,
        address base,
        bytes32 orderHash
    )
        internal returns (uint256 remainingToken, uint256 baseExecute)
    {
        uint256 tokenGet = calculateTokenGet(amountSell, amountBuy, _remainingToken, isBuy, orderHash);
        uint256 baseGet = calculateBaseGet(amountSell, amountBuy, isBuy, tokenGet);
        uint256 fee = calculateFee(gasFee, data, baseGet, orderHash, false, base == 0);
        updateUserBalance(data, isBuy, baseGet, tokenGet, fee, token, base);
        orderFills[orderHash] = orderFills[orderHash].add(tokenGet);
        remainingToken = _remainingToken.sub(tokenGet);
        baseExecute = _baseExecute.add(baseGet);
        if (tradeEventEnabled) {
            TradeSuccess(
                userId2Address[data & USER_MASK],
                baseGet,
                tokenGet,
                isBuy,
                fee
            );
        }
    }

    function updateUserBalance(
        uint256 data,
        bool isBuy,
        uint256 baseGet,
        uint256 tokenGet,
        uint256 fee,
        address token,
        address base
    )
        internal
    {
        address user = userId2Address[data & USER_MASK];
        uint256 baseFee = fee;
        uint256 joyFee = 0;
        if ((base == 0 ? (data & JOY_PRICE_MASK) >> 164 : (data & TOKEN_JOY_PRICE_MASK) >> 64) != 0) {
            joyFee = fee;
            baseFee = 0;
        }

        if (isBuy) {  
            balances[base][user] = balances[base][user].sub(baseGet).sub(baseFee);
            balances[token][user] = balances[token][user].add(tokenGet);
        } else {
            balances[base][user] = balances[base][user].add(baseGet).sub(baseFee);
            balances[token][user] = balances[token][user].sub(tokenGet);
        }

        if (joyFee != 0) {
            balances[joyToken][user] = balances[joyToken][user].sub(joyFee);
            balances[joyToken][joysoWallet] = balances[joyToken][joysoWallet].add(joyFee);
        } else {
            balances[base][joysoWallet] = balances[base][joysoWallet].add(baseFee);
        }
    }

    function calculateFee(
        uint256 gasFee,
        uint256 data,
        uint256 baseGet,
        bytes32 orderHash,
        bool isTaker,
        bool isEthOrder
    )
        internal view returns (uint256)
    {
        uint256 fee = orderFills[orderHash] == 0 ? gasFee : 0;
        uint256 txFee = baseGet.mul(isTaker ? (data & TAKER_FEE_MASK) >> 208 : (data & MAKER_FEE_MASK) >> 192) / 10000;
        uint256 joyPrice = isEthOrder ? (data & JOY_PRICE_MASK) >> 164 : (data & TOKEN_JOY_PRICE_MASK) >> 64;
        if (joyPrice != 0) {
            txFee = isEthOrder ? txFee / (10 ** 5) / joyPrice : txFee * (10 ** 12) / joyPrice;
        }
        return fee.add(txFee);
    }

    function calculateBaseGet(
        uint256 amountSell,
        uint256 amountBuy,
        bool isBuy,
        uint256 tokenGet
    )
        internal pure returns (uint256)
    {
        return isBuy ? tokenGet.mul(amountSell) / amountBuy : tokenGet.mul(amountBuy) / amountSell;
    }

    function calculateTokenGet(
        uint256 amountSell,
        uint256 amountBuy,
        uint256 remainingToken,
        bool isBuy,
        bytes32 orderHash
    )
        internal view returns (uint256)
    {
        uint256 makerRemainingToken = isBuy ? amountBuy : amountSell;
        makerRemainingToken = makerRemainingToken.sub(orderFills[orderHash]);
        require(makerRemainingToken > 0);  
        return makerRemainingToken >= remainingToken ? remainingToken : makerRemainingToken;
    }
}