 

pragma solidity ^0.5.7;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);  

    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface KyberInterface {

    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    ) external payable returns (uint);

    function getExpectedRate(address src, address dest, uint srcQty) external view returns (uint, uint);

}


contract Helper {

    address public kyberProxy = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
    address public ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public daiAddr = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public cdaiAddr = 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC;
    address payable public admin = 0x372e2D6f74eFA2C5A4C72DAC4A31da09E8505995;

    function setApproval(IERC20 tknContract, address to, uint srcAmt) internal returns (uint) {
        uint tokenAllowance = tknContract.allowance(address(this), to);
        if (srcAmt > tokenAllowance) {
            tknContract.approve(to, 2**255);
        }
    }

}


contract BankResolver is Helper {

    function swapAndLend(address src, uint srcAmt) public payable {

        if (src != ethAddr) {
            setApproval(IERC20(src), kyberProxy, srcAmt);
            require(IERC20(src).transferFrom(msg.sender, address(this), srcAmt), "Token-Approved?");
        }

        if (src == ethAddr) {
            require(msg.value != 0, "No-Eth-To-Swap");
            KyberInterface(kyberProxy).trade.value(msg.value)(
                src,
                msg.value,
                daiAddr,
                address(this),
                2**255,
                0,
                address(0)
            );
        } else if (src != daiAddr) {
            require(msg.value != 0, "No-Token-To-Swap");
            KyberInterface(kyberProxy).trade.value(0)(
                src,
                srcAmt,
                daiAddr,
                address(this),
                2**255,
                0,
                address(0)
            );
        }

        uint daiBal = IERC20(daiAddr).balanceOf(address(this));

        require(daiBal != 0, "No-Dai-To-Deposit");

        CTokenInterface cDaiContract = CTokenInterface(cdaiAddr);
        assert(cDaiContract.mint(daiBal) == 0);

        uint cdaiBal = cDaiContract.balanceOf(address(this));

        require(cDaiContract.transfer(msg.sender, cdaiBal), "Transfer-failed");

    }

    function transferLockedAsset(address token) public {
        if (token == ethAddr) {
            admin.transfer(address(this).balance);
        } else {
            uint tokenBal = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(admin, tokenBal);
        }
    }

}


contract PocketBank is BankResolver {

    constructor() public {
        setApproval(IERC20(daiAddr), cdaiAddr, 10**30);
    }

    function() external payable {}

}