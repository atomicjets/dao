# DAO framework 1.0 manual

## Table of Contents

1. [Overview](#overview)
2. [Getting started](#getting-started)
3. [Ðevelopment](#develop)
4. [Ðesign philosophy](#design)

## Overview

The TL;DR is that smart-contract systems is viewed as a set of actions that users can take. Each action is defined by three separate parts:
 
1. What it does
2. Who is allowed to do it 
3. The data it is operating on

The DAO framework is made to facilitate actions, and to help in keeping the different parts separate. It does so by dividing contracts up into classes.

### Application architecture

There are three main classes of contracts in a DAO framework application: Libraries, Databases and Actions.

![DaoCore](./images/dao-core.png)

#### Libraries

Libraries are plain Solidity libraries. These are not considered part of the system like databases and actions contracts because they are not registered with DaoCore, but they could be created together with the other contracts when a system is deployed.

#### Databases

Database contracts are bare-bones storage contracts. They contain only the functionality needed to read and write data to storage. The data they work with would usually be structured (though the actual struct definitions may be put in libraries), and they would usually have a collection interface, like a map or a set.

#### Actions contracts

Actions contracts contains a number of actions that can be taken by users. There could for example be a 'users' actions contract and a corresponding user database. The actions are functions in the actions contract and could do anything, like for example registering, modifying and removing users.

#### Modules

A module is a set of actions contracts and/or database contracts that makes up a functional unit. The framework comes with a set of different modules such as `dao-users` and `dao-currency`.

Modules may be self-contained, or depend on other modules. The thing they all have in common is they all depend on the `dao-core` contracts (`Doug` at the very least).

![ModuleView](./images/module-view.png)

There is no special procedure for registering a module. At least not in the first version of the framework. The way you do it is simply by creating a script that deploys the actions and database contracts, register them with Doug, and hook them up with the contracts they depend on. There is nothing in the code that states "this contract is part of module X" - nor is there any logic that depends on any data like that.

#### Notes

This separation is not made with the application / domain layer OO circle-jerk in mind; it's made by necessity, because of how Ethereum contracts and Solidity works. There is more about this in the design philosophy section.

The reason there isn't a separate permissions layer is for efficiency reasons. Permissions are normally part of the actions contract, or put in a separate contract referred to by the actions contract. This may change in the next iteration.

### DAO permissions model

There are three main types of access in this system:

1. **Root access**. This is managed by Doug, and handles permissions to add and remove contracts from the system, and changing core properties like whether or not contracts can be overwritten, and replacing the core premissions management system itself.

2. **Database access**. The system automatically gives actions-contracts write access to all the registered databases.

3. **User access**. This includes access to all actions except those that involves Doug. The application maker is in full control over these permissions. It could be handled per-contract or on a system wide basis (or both).

## Getting Started

The easiest way to get started is by looking at the [contracts](https://github.com/smartcontractproduction/dao/tree/master/dao-core/contracts) in `dao-core`. The contracts can also be deployed to a running Ethereum node using the deployment script in `dao-core/script/ethereum`.

There are also [tutorials](https://github.com/smartcontractproduction/dao/blob/master/docs/Tutorials.md). They teach how to write contracts and integrate them with the framework.

<a name="develop"></a>
## Ðevelopment

This section contains a more detailed description, for developers.

TODO

<a name="design"></a>
## Ðesign philosophy

The purpose of the dao-core is to provide a solid base for advanced systems of Ethereum contracts. The goal is to make the system:

- Efficient. Should not add extra database bloat or slow things down unnecessarily.

- Flexible. You should be able to replace components when they become outdated, or bugs are discovered.

- Reliable. The system should be secure, which means it should be protected against attacks as well as mistakes made by users and developers.

Striking a good balance can be difficult, as it is in all types of programs. It requires some insight into how the gas system, contract-calling, and the database works.

##### Gas

Gas is used to pay for both processing power and database storage on the public Ethereum chain, because every full node has to execute all transactions, and store all the data. The gas cost for each VM instruction can be found in the table on page 20 of the [Ethereum Yellow Paper](http://gavwood.com/paper.pdf).

It's worth noting that as of 2016-01-10, simple operations can cost 1 or a few gas, but writing one word (up to 32 bytes of data) costs 20000. This means contract optimization can be summed up by two words - **AVOID STORAGE**. Things you can do is to avoid collections that requires extra data per element, instantiating new contracts, and if a function stores user data it should normally be careful with un-bounded strings and arrays.

##### Contract calling

Contracts that has been added to the Ethereum chain can be transacted to by anyone, which means that anyone can invoke the functions they expose. If a function invocation involves write operations you will normally start by checking if the caller has the permission to run it. This could be done for example by pre-registering an account as the administrator (or owner), and then check if the caller is that account. This is an example:
 

``` javascript
contract Destructible {
    
    address _owner;
    
    function Destructible(address owner) {
        _owner = owner;
    }
    
    function destroy() {
        if (msg.sender == _owner) 
            selfdestruct(_owner);
    }
    
}


contract IncrediblyUseful is Destructible {
    
    function IncrediblyUseful() Destructible(msg.sender) {}
    
}
```

In this case, a contract that extends `SelfDestructible` will have a `destroy` function for self destruction. This function is public, and can be invoked by anyone, but unless their address is the same as `owner`, it will not pass the guard and nothing will happen. For example, in the  `IncrediblyUseful` contract (which can do nothing but self-destruct), the owner would always be the account that created the contract.

##### The database

Ethereum contracts have access to a database so that they can persist the values of their fields between calls. The big problem is that the storage of a particular contract can only be accessed by the code in that contract, and that code is immutable. If there are bugs in the code, or you need to add new functionality, you can't just update it, restart, and keep going; you have to create an entirely new contract. The old contract will still have the data in it though, and you still have to go through the old code to make changes to that data.

The reason for this is that it allows for trust-less systems. If the code is immutable, and the rules are set in advance, then it is possible to create contracts that can be called by anyone without them having to worry about any changes. This is great for oracles and other things.

The purpose of the database and actions contract separation is to work around this limitation. Certain contracts have to be managed, for example those that involve transfers of valuable assets, where users has to know that the actions they and others take are legally binding.

Database contracts would normally work like very basic collections and provide an interface for reading, writing and modifying the data. Additionally, they only need to do one simple check to see if the caller has the right permission. Admittedly it will cost a bit more gas then when everything is lumped together into one contract, but the cost is in most cases negligible (a few hundred gas).

It's worth pointing out that a lot of the difficulties with contracts doesn't come with basic usage. "I can test my contract to see if it works, why would it all over sudden break???". That is a bad question, because most contracts that are part of a system will depend on other contracts - most importantly the ones that handles account permissions - and some would likely be replaceable. A user calling a contract will often lead to a series of intra-system contract-to-contract calls. Changing one of those contract could have effects on the others, and those effects could sometimes be hard to predict; some could even be irreversible.

#### Avoiding complexity

The DAO framework has a clear separation between its different components. The `dao-core` library, for example, requires only two contracts to be deployed, Doug and Permission, because that's all it needs. 

There is also a clear separation of administrative rights. For example, if a managed system is set up, the account managing users and the account managing Doug does not have to be the same (although it could be). It might seem like this makes it more complicated, rather then less, but contract systems and permissions structures can both become very complex, very fast, so dividing them up into components usually pays off in the end. 

#### A note on public and private chains

The dao-core is designed with public chains in mind, but not the public Ethereum chain. This is mostly due to gas. The purpose of the gas system is to regulate the public Ethereum chain, and in practice it only allow trivial systems because of how restrictive it is. At least for now. An application-specific side-chain would have fewer contracts in it and less data to store, meaning it could have lower gas costs and a higher max limit in blocks. 

When it comes to private chains, i.e. chains that are managed by a single entity that does all the validation, I don't think there is a strong use case for the dao framework. If the chain is private and application specific, the proprietor might as well include the smart-contract logic in the client itself and save themselves all of the EVM overhead (and having to work in a new and somewhat difficult language). The usefulness of private chains (if any) is still being debated, and lots of research is going on, but I can't see any good use-case other then experimentation, or to prepare before the system is eventually put on a public (or some kind of semi-public) chain.

For these reasons, the dao framework may evolve into two different versions; one for big systems, and a hyper-optimized mini version for the public Ethereum chain.
