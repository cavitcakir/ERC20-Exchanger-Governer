pragma solidity ^0.8.0;

import "./token.sol";
import "./govern.sol";

contract Exchanger {

    Governer public governer;
    constructor (address  _governer_addrs) {
        governer = Governer(_governer_addrs);
    }


    function transfer(address from_addrs, address to_addrs, uint256 amount) public returns (bool success) {
        HW2Token token1 = HW2Token(from_addrs);
        HW2Token token2 = HW2Token(to_addrs);

        require(governer.registered_tokens(from_addrs) == true,"from_addrs is not registerd");
        require(governer.registered_tokens(to_addrs) == true,"to_addrs is not registered");


        // Verify allowance
        // This must be manually set by the user for security
        // (at least I did not find any other way)
        require(token1.allowance(msg.sender,address(this)) >= amount, "User allowance error!");

        // Check balance of contract and user
        // (user part is probably unnecessary since it is checked in the first transfer)
        require(token1.balanceOf(msg.sender) >= amount, "User balance error!");
        require(token2.balanceOf(address(this)) >= amount, "Contract balance error!");

        // Take token1 from the user (make sure it succeeds)
        // Should not fail since we checked the balance but just to make sure
        require(token1.transferFrom(msg.sender,address(this),amount), "Transfer (from) error!");

        // Give token2 to user from contract's address
        require(token2.transfer(msg.sender,amount),"Transfer (to) error!");

        return true;
    }
}
