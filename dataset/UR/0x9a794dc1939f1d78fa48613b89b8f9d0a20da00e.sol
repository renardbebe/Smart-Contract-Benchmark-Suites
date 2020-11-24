 

/* Simple token - simple token for PreICO and ICO
   Copyright (C) 2017  Sergey Sherkunov <<a class="__cf_email__" data-cfemail="79151c101715180e0c1739151c101715180e0c1757160b1e" href="/cdn-cgi/l/email-protection">[email protected]</a>>
   Copyright (C) 2017  OOM.AG <<a class="__cf_email__" data-cfemail="0861666e674867676526696f" href="/cdn-cgi/l/email-protection">[email protected]</a>>

   This file is part of simple token.

   Token is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https: 

pragma solidity ^0.4.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;

        assert(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assert(b <= a);

        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;

        assert(c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a;

        if(a > b)
           c = b;
    }
}

contract ABXToken {
    using SafeMath for uint256;

    address public owner;

    address public minter;

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed oldTokensHolder,
                   address indexed newTokensHolder, uint256 tokensNumber);

     
     
    event Transfer(address indexed tokensSpender,
                   address indexed oldTokensHolder,
                   address indexed newTokensHolder, uint256 tokensNumber);

    event Approval(address indexed tokensHolder, address indexed tokensSpender,
                   uint256 newTokensNumber);

     
     
    event Approval(address indexed tokensHolder, address indexed tokensSpender,
                   uint256 oldTokensNumber, uint256 newTokensNumber);

    modifier onlyOwner {
        require(owner == msg.sender);

        _;
    }

     
     
     
     
    modifier checkPayloadSize(uint256 size) {
        require(msg.data.length == size + 4);

        _;
    }

    modifier onlyNotNullTokenHolder(address tokenHolder) {
        require(tokenHolder != address(0));

        _;
    }

    function ABXToken(string _name, string _symbol, uint8 _decimals,
                      uint256 _totalSupply) public {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply.mul(10 ** uint256(decimals));

        require(decimals <= 77);

        balanceOf[this] = totalSupply;
    }

    function setOwner(address _owner) public onlyOwner returns(bool) {
        owner = _owner;

        return true;
    }

    function setMinter(address _minter) public onlyOwner returns(bool) {
        safeApprove(this, minter, 0);

        minter = _minter;

        safeApprove(this, minter, balanceOf[this]);

        return true;
    }

     
     
     
     
    function transfer(address newTokensHolder, uint256 tokensNumber) public
                     checkPayloadSize(2 * 32) returns(bool) {
        transfer(msg.sender, newTokensHolder, tokensNumber);

        return true;
    }

     
     
     
     
     
     
     
    function transferFrom(address oldTokensHolder, address newTokensHolder,
                          uint256 tokensNumber) public checkPayloadSize(3 * 32)
                         returns(bool) {
        allowance[oldTokensHolder][msg.sender] =
            allowance[oldTokensHolder][msg.sender].sub(tokensNumber);

        transfer(oldTokensHolder, newTokensHolder, tokensNumber);

        Transfer(msg.sender, oldTokensHolder, newTokensHolder, tokensNumber);

        return true;
    }

     
     
     
     
    function approve(address tokensSpender, uint256 newTokensNumber) public
                    checkPayloadSize(2 * 32) returns(bool) {
        safeApprove(msg.sender, tokensSpender, newTokensNumber);

        return true;
    }

     
     
     
     
     
     
     
    function approve(address tokensSpender, uint256 oldTokensNumber,
                     uint256 newTokensNumber) public checkPayloadSize(3 * 32)
                    returns(bool) {
        require(allowance[msg.sender][tokensSpender] == oldTokensNumber);

        unsafeApprove(msg.sender, tokensSpender, newTokensNumber);

        Approval(msg.sender, tokensSpender, oldTokensNumber, newTokensNumber);

        return true;
    }

    function transfer(address oldTokensHolder, address newTokensHolder,
                      uint256 tokensNumber) private
                      onlyNotNullTokenHolder(oldTokensHolder) {
        balanceOf[oldTokensHolder] =
            balanceOf[oldTokensHolder].sub(tokensNumber);

        balanceOf[newTokensHolder] =
            balanceOf[newTokensHolder].add(tokensNumber);

        Transfer(oldTokensHolder, newTokensHolder, tokensNumber);
    }

     
     
    function unsafeApprove(address tokensHolder, address tokensSpender,
                           uint256 newTokensNumber) private
                          onlyNotNullTokenHolder(tokensHolder) {
        allowance[tokensHolder][tokensSpender] = newTokensNumber;

        Approval(msg.sender, tokensSpender, newTokensNumber);
    }
    
     
     
    function safeApprove(address tokensHolder, address tokensSpender,
                         uint256 newTokensNumber) private {
        require(allowance[tokensHolder][tokensSpender] == 0 ||
                newTokensNumber == 0);

        unsafeApprove(tokensHolder, tokensSpender, newTokensNumber);
    }
}