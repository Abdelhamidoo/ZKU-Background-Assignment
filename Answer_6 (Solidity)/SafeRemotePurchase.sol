// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;
contract Purchase {
    uint public value;
    //*** Stores the time when the confirmPurchase() function is called
    uint public confirmPurchaseTime;
    //*** Stores the time when the contract is deployed
    uint public contractDeploymentTime;
    address payable public seller;
    address payable public buyer;

    //*** I've removed the "Release" state value because it's not used anymore 
    enum State { Created, Locked, Inactive }
    // The state variable has a default value of the first member, `State.created`
    State public state;

    modifier condition(bool condition_) {
        require(condition_);
        _;
    }

    /// Only the buyer can call this function.
    error OnlyBuyer();
    /// Only the seller can call this function.
    error OnlySeller();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();

    modifier onlyBuyer() {
        if (msg.sender != buyer)
            revert OnlyBuyer();
        _;
    }

    modifier onlySeller() {
        if (msg.sender != seller)
            revert OnlySeller();
        _;
    }

    modifier inState(State state_) {
        if (state != state_)
            revert InvalidState();
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    // Ensure that `msg.value` is an even number.
    // Division will truncate if it is an odd number.
    // Check via multiplication that it wasn't an odd number.
    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        if ((2 * value) != msg.value){
            revert ValueNotEven();
        }
        contractDeploymentTime = block.timestamp;
    }

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the seller before
    /// the contract is locked.
    function abort()
        external
        onlySeller
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        // We use transfer here directly. It is
        // reentrancy-safe, because it is the
        // last call in this function and we
        // already changed the state.
        seller.transfer(address(this).balance);
    }

    /// Confirm the purchase as buyer.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function confirmPurchase()
        external
        inState(State.Created)
        condition(msg.value == (2 * value))
        payable
    {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
        confirmPurchaseTime = block.timestamp;
    }

    //*** completePurchase() is a function which merges both 
    //*** confirmReceived() and refundSeller() function
    //*** It refunds both the buyer and the seller
    //*** It can be called only if the current state is "Locked"
    //*** and either the buyer is the caller or ≥5 minutes have
    //*** elapsed since the buyer called confirmPurchase()
    function completePurchase()
        external
        inState(State.Locked)
        condition(msg.sender == buyer || block.timestamp - confirmPurchaseTime >= 5 * 60) 
        {
            emit ItemReceived();
            buyer.transfer(value);
            emit SellerRefunded();
            state = State.Inactive;
            seller.transfer(3 * value);
    }
    
    //*** This function is for viewing the current balance of
    //*** our smart contract
    function currentBalance() public view returns(uint) {
        return address(this).balance;
    }

}

//*** My comments starts with ***