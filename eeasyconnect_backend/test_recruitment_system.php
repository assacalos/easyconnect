<?php

require_once 'vendor/autoload.php';

use App\Models\RecruitmentRequest;
use App\Models\RecruitmentApplication;
use App\Models\RecruitmentDocument;
use App\Models\RecruitmentInterview;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test du Système de Gestion des Recrutements ===\n\n";

try {
    // 1. Vérifier les tables
    echo "1. Vérification des tables:\n";
    echo "   - Demandes de recrutement: " . RecruitmentRequest::count() . "\n";
    echo "   - Candidatures: " . RecruitmentApplication::count() . "\n";
    echo "   - Documents: " . RecruitmentDocument::count() . "\n";
    echo "   - Entretiens: " . RecruitmentInterview::count() . "\n";
    echo "   - Utilisateurs: " . User::count() . "\n";

    // 2. Créer une demande de recrutement de test
    echo "\n2. Test de création de demande de recrutement:\n";
    $user = User::first();
    if (!$user) {
        $user = User::create([
            'nom' => 'Test',
            'prenom' => 'User',
            'email' => 'test@example.com',
            'password' => bcrypt('password'),
            'role' => 5,
            'telephone' => '0123456789',
            'date_naissance' => '1990-01-01',
            'adresse' => 'Test Address',
            'ville' => 'Test City',
            'pays' => 'Test Country'
        ]);
        echo "   - Utilisateur de test créé: {$user->email}\n";
    } else {
        echo "   - Utilisateur existant trouvé: {$user->email}\n";
    }

    $recruitmentRequest = RecruitmentRequest::create([
        'title' => 'Développeur Full Stack',
        'department' => 'IT',
        'position' => 'Développeur',
        'description' => 'Nous recherchons un développeur full stack expérimenté pour rejoindre notre équipe.',
        'requirements' => 'Bac+3 minimum, 2-5 ans d\'expérience, maîtrise des technologies web modernes',
        'responsibilities' => 'Développement d\'applications web, maintenance du code, collaboration avec l\'équipe',
        'number_of_positions' => 2,
        'employment_type' => 'full_time',
        'experience_level' => 'mid',
        'salary_range' => '120 000 - 200 000 FCFA',
        'location' => 'Abidjan',
        'application_deadline' => '2024-12-31',
        'status' => 'published',
        'published_at' => now(),
        'published_by' => $user->id,
        'created_by' => $user->id
    ]);
    
    echo "   ✅ Demande de recrutement créée: {$recruitmentRequest->title}\n";
    echo "   - Département: {$recruitmentRequest->department}\n";
    echo "   - Poste: {$recruitmentRequest->position}\n";
    echo "   - Statut: {$recruitmentRequest->status_libelle}\n";
    echo "   - Type d'emploi: {$recruitmentRequest->employment_type_libelle}\n";
    echo "   - Niveau d'expérience: {$recruitmentRequest->experience_level_libelle}\n";
    echo "   - Fourchette de salaire: {$recruitmentRequest->salary_range}\n";
    echo "   - Localisation: {$recruitmentRequest->location}\n";
    echo "   - Date limite: {$recruitmentRequest->application_deadline->format('Y-m-d')}\n";
    echo "   - Publié par: {$recruitmentRequest->publisher_name}\n";

    // 3. Test des candidatures
    echo "\n3. Test des candidatures:\n";
    $application = RecruitmentApplication::create([
        'recruitment_request_id' => $recruitmentRequest->id,
        'candidate_name' => 'Jean Dupont',
        'candidate_email' => 'jean.dupont@example.com',
        'candidate_phone' => '0123456789',
        'candidate_address' => 'Abidjan, Côte d\'Ivoire',
        'cover_letter' => 'Lettre de motivation détaillée...',
        'resume_path' => '/documents/cv_jean_dupont.pdf',
        'portfolio_url' => 'https://jeandupont.portfolio.com',
        'linkedin_url' => 'https://linkedin.com/in/jeandupont',
        'status' => 'pending',
        'notes' => 'Candidat prometteur'
    ]);
    echo "   ✅ Candidature créée: {$application->candidate_name}\n";
    echo "   - Email: {$application->candidate_email}\n";
    echo "   - Téléphone: {$application->candidate_phone}\n";
    echo "   - Statut: {$application->status_libelle}\n";
    echo "   - CV: {$application->resume_path}\n";
    echo "   - Portfolio: {$application->portfolio_url}\n";
    echo "   - LinkedIn: {$application->linkedin_url}\n";

    // 4. Test des documents
    echo "\n4. Test des documents:\n";
    $document = RecruitmentDocument::create([
        'application_id' => $application->id,
        'file_name' => 'CV_Jean_Dupont.pdf',
        'file_path' => '/documents/cv_jean_dupont.pdf',
        'file_type' => 'pdf',
        'file_size' => 1024000,
        'uploaded_at' => now()
    ]);
    echo "   ✅ Document créé: {$document->file_name}\n";
    echo "   - Type: {$document->file_type}\n";
    echo "   - Taille: {$document->formatted_file_size}\n";
    echo "   - Extension: {$document->file_extension}\n";
    echo "   - Est PDF: " . ($document->is_pdf ? 'Oui' : 'Non') . "\n";
    echo "   - Est image: " . ($document->is_image ? 'Oui' : 'Non') . "\n";

    // 5. Test des entretiens
    echo "\n5. Test des entretiens:\n";
    $interview = RecruitmentInterview::create([
        'application_id' => $application->id,
        'scheduled_at' => now()->addDays(7),
        'location' => 'Bureau principal',
        'type' => 'in_person',
        'notes' => 'Entretien technique et culturel',
        'status' => 'scheduled',
        'interviewer_id' => $user->id
    ]);
    echo "   ✅ Entretien créé\n";
    echo "   - Date programmée: {$interview->scheduled_at->format('Y-m-d H:i:s')}\n";
    echo "   - Lieu: {$interview->location}\n";
    echo "   - Type: {$interview->type_libelle}\n";
    echo "   - Statut: {$interview->status_libelle}\n";
    echo "   - Intervieweur: {$interview->interviewer_name}\n";
    echo "   - À venir: " . ($interview->is_upcoming ? 'Oui' : 'Non') . "\n";
    echo "   - Aujourd\'hui: " . ($interview->is_today ? 'Oui' : 'Non') . "\n";

    // 6. Test des statistiques
    echo "\n6. Test des statistiques:\n";
    $stats = RecruitmentRequest::getRecruitmentStats();
    echo "   - Total demandes: {$stats['total_requests']}\n";
    echo "   - Brouillons: {$stats['draft_requests']}\n";
    echo "   - Publiées: {$stats['published_requests']}\n";
    echo "   - Fermées: {$stats['closed_requests']}\n";
    echo "   - Annulées: {$stats['cancelled_requests']}\n";
    echo "   - Total candidatures: {$stats['total_applications']}\n";
    echo "   - En attente: {$stats['pending_applications']}\n";
    echo "   - Pré-sélectionnées: {$stats['shortlisted_applications']}\n";
    echo "   - Interviewées: {$stats['interviewed_applications']}\n";
    echo "   - Embauchées: {$stats['hired_applications']}\n";
    echo "   - Rejetées: {$stats['rejected_applications']}\n";
    echo "   - Temps moyen de traitement: " . number_format($stats['average_application_time'], 1) . " jours\n";

    // 7. Test des filtres
    echo "\n7. Test des filtres:\n";
    $draftRequests = RecruitmentRequest::draft()->count();
    $publishedRequests = RecruitmentRequest::published()->count();
    $closedRequests = RecruitmentRequest::closed()->count();
    $cancelledRequests = RecruitmentRequest::cancelled()->count();
    $itRequests = RecruitmentRequest::byDepartment('IT')->count();
    $fullTimeRequests = RecruitmentRequest::byEmploymentType('full_time')->count();
    $midLevelRequests = RecruitmentRequest::byExperienceLevel('mid')->count();
    $expiringRequests = RecruitmentRequest::expiring()->count();
    $expiredRequests = RecruitmentRequest::expired()->count();
    
    echo "   - Demandes brouillons: {$draftRequests}\n";
    echo "   - Demandes publiées: {$publishedRequests}\n";
    echo "   - Demandes fermées: {$closedRequests}\n";
    echo "   - Demandes annulées: {$cancelledRequests}\n";
    echo "   - Demandes IT: {$itRequests}\n";
    echo "   - Demandes temps plein: {$fullTimeRequests}\n";
    echo "   - Demandes niveau intermédiaire: {$midLevelRequests}\n";
    echo "   - Demandes expirant: {$expiringRequests}\n";
    echo "   - Demandes expirées: {$expiredRequests}\n";

    // 8. Test des candidatures
    echo "\n8. Test des candidatures:\n";
    $applicationStats = RecruitmentApplication::getApplicationStats($recruitmentRequest->id);
    echo "   - Total candidatures: {$applicationStats['total_applications']}\n";
    echo "   - En attente: {$applicationStats['pending_applications']}\n";
    echo "   - Examinées: {$applicationStats['reviewed_applications']}\n";
    echo "   - Pré-sélectionnées: {$applicationStats['shortlisted_applications']}\n";
    echo "   - Interviewées: {$applicationStats['interviewed_applications']}\n";
    echo "   - Embauchées: {$applicationStats['hired_applications']}\n";
    echo "   - Rejetées: {$applicationStats['rejected_applications']}\n";
    echo "   - Temps moyen de traitement: " . number_format($applicationStats['average_processing_time'], 1) . " jours\n";

    // 9. Test des entretiens
    echo "\n9. Test des entretiens:\n";
    $interviewStats = RecruitmentInterview::getInterviewStats($application->id);
    echo "   - Total entretiens: {$interviewStats['total_interviews']}\n";
    echo "   - Programmés: {$interviewStats['scheduled_interviews']}\n";
    echo "   - Terminés: {$interviewStats['completed_interviews']}\n";
    echo "   - Annulés: {$interviewStats['cancelled_interviews']}\n";
    echo "   - À venir: {$interviewStats['upcoming_interviews']}\n";
    echo "   - Aujourd\'hui: {$interviewStats['today_interviews']}\n";
    echo "   - En retard: {$interviewStats['overdue_interviews']}\n";
    echo "   - Durée moyenne: " . number_format($interviewStats['average_duration'], 1) . " minutes\n";

    // 10. Test des accesseurs
    echo "\n10. Test des accesseurs:\n";
    echo "   - Créateur: {$recruitmentRequest->creator_name}\n";
    echo "   - Publieur: {$recruitmentRequest->publisher_name}\n";
    echo "   - Approbateur: {$recruitmentRequest->approver_name}\n";
    echo "   - Peut publier: " . ($recruitmentRequest->can_publish ? 'Oui' : 'Non') . "\n";
    echo "   - Peut fermer: " . ($recruitmentRequest->can_close ? 'Oui' : 'Non') . "\n";
    echo "   - Peut annuler: " . ($recruitmentRequest->can_cancel ? 'Oui' : 'Non') . "\n";
    echo "   - Peut éditer: " . ($recruitmentRequest->can_edit ? 'Oui' : 'Non') . "\n";
    echo "   - Expirant: " . ($recruitmentRequest->is_expiring ? 'Oui' : 'Non') . "\n";
    echo "   - Expiré: " . ($recruitmentRequest->is_expired ? 'Oui' : 'Non') . "\n";
    echo "   - Nombre de candidatures: {$recruitmentRequest->applications_count}\n";
    echo "   - Candidatures en attente: {$recruitmentRequest->pending_applications_count}\n";
    echo "   - Candidatures pré-sélectionnées: {$recruitmentRequest->shortlisted_applications_count}\n";
    echo "   - Candidatures embauchées: {$recruitmentRequest->hired_applications_count}\n";

    echo "\n✅ Test du système de recrutement terminé avec succès!\n";

} catch (\Exception $e) {
    echo "\n❌ Erreur lors du test: " . $e->getMessage() . "\n";
    echo "   Fichier: " . $e->getFile() . ":" . $e->getLine() . "\n";
}
