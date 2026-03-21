<?php

namespace App\Providers;

// use Illuminate\Support\Facades\Gate;
use App\Models\Devis;
use App\Models\Facture;
use App\Policies\DevisPolicy;
use App\Policies\FacturePolicy;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;

class AuthServiceProvider extends ServiceProvider
{
    /**
     * The model to policy mappings for the application.
     *
     * @var array<class-string, class-string>
     */
    protected $policies = [
        Devis::class => DevisPolicy::class,
        Facture::class => FacturePolicy::class,
    ];

    /**
     * Register any authentication / authorization services.
     */
    public function boot(): void
    {
        $this->registerPolicies();

        //
    }
}
